import { createClient } from "jsr:@supabase/supabase-js@2";

type Attachment = {
  id: string;
  bucket_id: string;
  object_path: string;
  thumbnail_bucket_id: string | null;
  thumbnail_path: string | null;
};

type Failure = {
  id?: string;
  stage: "config" | "rpc" | "storage" | "update";
  message: string;
};

const jsonHeaders = { "Content-Type": "application/json" };

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`missing ${name}`);
  }
  return value;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }

  const cleanupSecret = Deno.env.get("CHAT_MEDIA_CLEANUP_SECRET");
  if (!cleanupSecret) {
    return jsonResponse({ error: "cleanup secret is not configured" }, 500);
  }
  if (req.headers.get("x-cleanup-secret") !== cleanupSecret) {
    return new Response("forbidden", { status: 403 });
  }

  let admin;
  try {
    admin = createClient(requiredEnv("SUPABASE_URL"), requiredEnv("SUPABASE_SERVICE_ROLE_KEY"));
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "missing Supabase configuration",
    }, 500);
  }

  const failures: Failure[] = [];
  const { data, error } = await admin.rpc("chat_media_cleanup_candidates", { p_limit: 100 });
  if (error) {
    return jsonResponse({
      scanned: 0,
      deleted: 0,
      failures: [{ stage: "rpc", message: error.message }],
    }, 500);
  }

  const attachments = (data ?? []) as Attachment[];
  let deleted = 0;

  for (const attachment of attachments) {
    const rowFailures: Failure[] = [];
    const original = await admin.storage
      .from(attachment.bucket_id)
      .remove([attachment.object_path]);
    if (original.error) {
      rowFailures.push({ id: attachment.id, stage: "storage", message: original.error.message });
    }

    if (attachment.thumbnail_bucket_id && attachment.thumbnail_path) {
      const thumbnail = await admin.storage
        .from(attachment.thumbnail_bucket_id)
        .remove([attachment.thumbnail_path]);
      if (thumbnail.error) {
        rowFailures.push({ id: attachment.id, stage: "storage", message: thumbnail.error.message });
      }
    }

    if (rowFailures.length > 0) {
      failures.push(...rowFailures);
      continue;
    }

    const { error: updateError } = await admin
      .from("message_attachments")
      .update({ status: "deleted", deleted_at: new Date().toISOString() })
      .eq("id", attachment.id);

    if (updateError) {
      failures.push({ id: attachment.id, stage: "update", message: updateError.message });
      continue;
    }

    deleted++;
  }

  return jsonResponse({ scanned: attachments.length, deleted, failures });
});
