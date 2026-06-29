# Chat Media Messages Design

## Goal

Add safe photo and video messages to both 1:1 match chat and keo group chat.
The first version supports exactly one media attachment per message. Multiple
photos or mixed albums are out of scope for this iteration.

## User-Approved Direction

Use the MVP direction:

- One message can be text, one image, or one video.
- If a user selects several images, the app sends them as separate messages.
- Support both match chat and keo group chat.
- Store files in private Supabase Storage buckets.
- Store attachment metadata in Postgres, not as public URLs in message bodies.
- Hide deleted media from the UI immediately, then physically delete Storage
  objects later through scheduled cleanup.

## Current Project Context

The existing chat stack is text-only:

- `public.messages.body` is required and limited to 1-2000 characters.
- `public.send_message(p_thread, p_body)` sends 1:1 match messages.
- `public.send_keo_message(p_keo, p_body)` sends keo group messages.
- Realtime private broadcasts include `id`, `thread_id`, `sender_id`, `body`,
  and `created_at`.
- Match access is checked by `app_private.in_match`.
- Keo access is checked by `app_private.in_keo`.
- Moderation already hides messages through `messages.hidden`.
- Account deletion already hides a departing user's messages immediately.
- Supabase local Storage is enabled with a global `50MiB` limit, but no chat
  media bucket is configured yet.

## Product Scope

### In Scope

- Pick one image or one video from the device and send it in chat.
- Show a local preview before sending.
- Show upload progress while sending.
- Render image bubbles and video bubbles in chat history and realtime.
- Allow sender deletion of their own media message.
- Hide deleted media as "message deleted" in the thread.
- Allow existing report/moderation flow to act on media messages.
- Clean up orphan uploads and retention-expired files.

### Out of Scope

- Albums with multiple attachments in one message.
- Captions on media messages.
- In-app camera capture.
- Video transcoding pipeline.
- Public share links for chat media.
- Download-to-device controls.
- End-to-end encryption.

## Limits

Use conservative limits for the first release:

- Images:
  - MIME types: `image/jpeg`, `image/png`, `image/webp`.
  - Max size: `8MiB`.
- Videos:
  - MIME types: `video/mp4`, `video/quicktime`.
  - Max size: `25MiB`.
  - Max duration: `60 seconds`.
- Rate limit:
  - Keep existing text message rate limit.
  - Add a separate media send limit of `20 media messages per user per day`.

The app should validate limits before upload when it can, and the server must
validate them again before attaching the media to a message.

## Storage Model

Create two private buckets:

- `chat-images`
- `chat-videos`

Object paths do not use original filenames:

- Match image: `match/{thread_id}/{sender_id}/{attachment_id}.jpg`
- Match video: `match/{thread_id}/{sender_id}/{attachment_id}.mp4`
- Keo image: `keo/{keo_id}/{sender_id}/{attachment_id}.jpg`
- Keo video: `keo/{keo_id}/{sender_id}/{attachment_id}.mp4`

Thumbnail paths:

- Image thumbnail: `thumbs/match/{thread_id}/{sender_id}/{attachment_id}.jpg`
- Video thumbnail: `thumbs/keo/{keo_id}/{sender_id}/{attachment_id}.jpg`

MVP can use the original image as its preview if thumbnail generation is not
implemented immediately. Video needs at least a client-side or server-side
thumbnail before the bubble feels usable.

## Database Model

Keep `public.messages` as the durable event row, and add an attachment table.

Proposed `public.message_attachments` fields:

- `id uuid primary key default gen_random_uuid()`
- `message_id uuid references public.messages(id) on delete cascade`
- `thread_type text not null check (thread_type in ('match','keo'))`
- `thread_id uuid not null`
- `owner_id uuid not null references auth.users(id) on delete cascade`
- `media_type text not null check (media_type in ('image','video'))`
- `bucket_id text not null`
- `object_path text not null`
- `thumbnail_bucket_id text`
- `thumbnail_path text`
- `mime_type text not null`
- `size_bytes bigint not null`
- `width integer`
- `height integer`
- `duration_ms integer`
- `status text not null check (status in ('pending','attached','hidden','deleted'))`
- `created_at timestamptz not null default now()`
- `attached_at timestamptz`
- `soft_deleted_at timestamptz`
- `delete_after timestamptz`
- `deleted_at timestamptz`

`messages.body` should become nullable, or the system should store a small
sentinel body for media messages. The preferred option is to make `body`
nullable and add a message kind:

- `messages.kind text not null default 'text' check (kind in ('text','image','video'))`
- `body` is required only when `kind = 'text'`.

This keeps media messages first-class instead of hiding URLs inside text.

## Access Control

Storage buckets remain private.

RLS requirements:

- Only authenticated users can upload chat media.
- A user can upload only under their own `{sender_id}` path.
- A user can upload match media only if `app_private.in_match(thread_id)`.
- A user can upload keo media only if `app_private.in_keo(thread_id)`.
- A user can read media only if they can read the parent thread.
- A user can soft-delete only their own attachment message.
- Admin/moderation RPCs can hide/remove media through existing admin checks.

Client code must never use `service_role`. Physical Storage deletion runs from
trusted scheduled server code only.

## Send Flow

1. User taps attach in the chat composer.
2. App opens picker for image/video.
3. App checks type, size, and video duration.
4. App creates a pending attachment row through an RPC, receiving an
   `attachment_id`, bucket, and object path.
5. App uploads the file to private Storage at that object path.
6. App calls a send RPC with the pending attachment id.
7. Server validates:
   - caller owns the pending attachment;
   - caller is still a thread member;
   - object path belongs to the caller and thread;
   - media type, MIME, size, and duration are within limits;
   - attachment is still `pending`.
8. Server inserts a `messages` row with `kind = image` or `kind = video`.
9. Server attaches the row by setting `message_id`, `status = attached`,
   `attached_at = now()`.
10. Server broadcasts the new message with attachment metadata.

If upload succeeds but send fails, the attachment remains `pending` and cleanup
deletes it after 24 hours.

## Read Flow

History queries should fetch messages and their attached media metadata in one
repository call. Realtime payloads should include the same attachment metadata
for new messages so the UI does not need an immediate refetch.

The UI obtains display access through either:

- authenticated Storage download URLs, or
- short-lived signed URLs.

Use short TTL signed URLs if the Flutter image/video components need plain URLs.
A TTL of 5-10 minutes is enough; expired URLs can be refreshed when the bubble
comes back on screen.

## Delete And Retention

Deletion is two-phase:

1. Hide from product UI immediately.
2. Delete physical Storage objects later.

Rules:

- Pending attachment not sent: delete after `24 hours`.
- Sender deletes own media message: hide immediately, set `delete_after` to
  `now() + interval '30 days'`.
- Account deletion: hide immediately, set `delete_after` to `now() + interval '30 days'`.
- Admin remove after report: hide immediately, set `delete_after` to
  `now() + interval '7 days'`.
- Keo media for completed keos: set `delete_after` to `keo completed at + 90 days`.

Cleanup job:

- Runs on a schedule.
- Finds attachments with `delete_after <= now()` and `deleted_at is null`.
- Removes original object and thumbnail object from Storage.
- Sets `status = deleted`, `deleted_at = now()`.
- Leaves the metadata row for audit and UI tombstones.

## Moderation And Safety

Media messages use the existing report/admin pattern:

- Users can report a media message.
- Admin action `hide` hides the message and attachment.
- Admin action `remove` hides the message and schedules physical deletion.
- UI rules banner in keo chat remains relevant: no recording or photographing
  people without consent.

The app should strip image EXIF/GPS metadata before upload when possible.

## Error Handling

- Unsupported type: show "Dinh dang tep chua duoc ho tro."
- File too large: show "Tep qua lon de gui."
- Video too long: show "Video toi da 60 giay."
- Upload fails: keep composer preview and show retry.
- Send RPC fails after upload: show retry; cleanup will remove the pending file
  if the user abandons it.
- Signed URL expires: refresh the URL and retry rendering.
- User loses membership before sending: server rejects, app shows the existing
  not-in-thread style error.

## Flutter UI Changes

Shared chat UI should be extracted enough to avoid duplicating media behavior
between `ChatScreen` and `KeoChatScreen`.

Components:

- Attachment picker button in composer.
- Local preview sheet or inline preview row.
- Upload progress state.
- Media message bubble:
  - image preview;
  - video preview with play icon;
  - deleted/tombstone state;
  - failed/retry state for sender.
- Fullscreen image viewer.
- Video playback view.

Suggested dependencies:

- `image_picker` or `file_picker` for picking files.
- `video_player` for playback.
- A MIME/type helper if the selected picker does not reliably provide MIME.

## Testing

Database tests:

- Non-member cannot create pending attachment.
- Member can create pending attachment for a match.
- Confirmed keo member can create pending attachment for a keo.
- Sender can send pending image message.
- Sender cannot attach another user's pending attachment.
- Oversized/MIME-invalid attachment is rejected.
- Pending attachment cleanup target is queryable after 24 hours.
- Sender delete hides message and sets `delete_after`.
- Non-member cannot select attachment metadata.

Flutter tests:

- Repository calls create-pending, upload, and send in order.
- Media message JSON parses text and media payloads.
- Chat screen renders image bubble.
- Chat screen renders video bubble.
- Deleted media renders tombstone.
- Composer blocks oversized file before upload.
- Upload failure shows retry.

Manual emulator QA:

- Send one image in 1:1 chat.
- Send one video in 1:1 chat.
- Send one image in keo chat.
- Delete a media message and confirm tombstone.
- Reload app and confirm media still renders.
- Confirm unauthorized user cannot read the media object.

## Rollout

1. Ship behind app-side feature flag or environment flag.
2. Enable first for keo chat QA, then match chat.
3. Watch Storage usage and failed upload logs.
4. Revisit album support only after MVP media send/delete is stable.

## References Checked

- Supabase Storage file limits support global and per-bucket limits.
- Supabase Storage private buckets require RLS policies on `storage.objects`.
- Supabase Storage private assets can be served by authenticated download or
  time-limited signed URLs.
- Supabase recommends resumable upload for files larger than 6MB; MVP can use
  standard upload for images and should consider resumable upload for videos.
