import { createClient } from "jsr:@supabase/supabase-js@2";

// Ops-only: invoked manually per city. Secret-gated; NEVER exposed to the app.
Deno.serve(async (req) => {
  if (req.headers.get("x-ingest-secret") !== Deno.env.get("PLACES_INGEST_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }
  const { city, lat, lng, radius_m = 5000, style_tag = "k_style" } = await req.json();
  const res = await fetch("https://places.googleapis.com/v1/places:searchNearby", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": Deno.env.get("GOOGLE_PLACES_API_KEY")!,
      "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location",
    },
    body: JSON.stringify({
      includedTypes: ["karaoke"],
      maxResultCount: 20,
      locationRestriction: { circle: { center: { latitude: lat, longitude: lng }, radius: radius_m } },
    }),
  });
  const data = await res.json();
  const places: any[] = data.places ?? [];
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  let upserted = 0;
  for (const p of places) {
    if (!p.id) continue;
    const row = {
      name: p.displayName?.text ?? "Karaoke",
      address: p.formattedAddress ?? "",
      city,
      location: `SRID=4326;POINT(${p.location.longitude} ${p.location.latitude})`, // EWKT → geography
      style_tag,
      source: "places",
      places_id: p.id,
      is_active: true,
    };
    const { error } = await sb.from("venues").upsert(row, { onConflict: "places_id" });
    if (!error) upserted++;
  }
  return new Response(JSON.stringify({ found: places.length, upserted }), {
    headers: { "Content-Type": "application/json" },
  });
});
