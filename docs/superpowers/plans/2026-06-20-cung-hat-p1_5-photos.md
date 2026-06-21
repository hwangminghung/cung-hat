# Cùng Hát — P1.5 Profile Photos (optional) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optional profile photos: a user uploads one photo into a **private** per-uid storage bucket; others see it only via a **short-lived server-minted signed URL** (Edge Function, access-gated). No-photo profiles keep the monogram fallback.

**Architecture:** Builds on P0 (`profiles`) + P1 (`blocks`, deck card) + P3 (kèo roster). Migration `0023` adds `profiles.photo_path`, the private `profile-photos` bucket + owner-only `storage.objects` RLS, and `set_my_photo_path`. A `sign-photo` Edge Function mints a 60s signed URL for a target's photo if the caller is allowed (not blocked, target not soft-deleted). Flutter adds a `photos` capability (own upload + signed-URL viewer) reused by the candidate card and the kèo roster.

> **Migration number:** `0023` (appended after P7's 0022) so we don't renumber P2–P7. It has **no ordering dependency** (nothing else references `photo_path`), so P1.5 may be implemented at any point after P0 — or last.

**Tech Stack:** Supabase Storage (private bucket + RLS), Edge Function (service-role signed URL), `image_picker`, Riverpod 3, mocktail.

**Depends on:** P0 (`profiles`, RPC pattern), P1 (`blocks`, `CandidateCard`), P3 (`get_keo_roster`/`KeoMember`).

---

### Task 1: Migration 0023 — photo_path + private bucket + RLS + setter

**Files:**
- Create: `supabase/migrations/0023_photos.sql`, `supabase/tests/photos_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0023_photos.sql`:
```sql
alter table public.profiles add column if not exists photo_path text;

-- Private bucket; objects live under '{uid}/...'. Never public.
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', false)
on conflict (id) do nothing;

-- Owner-only CRUD on their own folder; nobody can directly read another user's object
-- (others go through the sign-photo Edge Function, which uses the service role).
create policy "own photos read" on storage.objects for select to authenticated
  using (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photos insert" on storage.objects for insert to authenticated
  with check (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photos update" on storage.objects for update to authenticated
  using (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photos delete" on storage.objects for delete to authenticated
  using (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create or replace function public.set_my_photo_path(p_path text)
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.profiles set photo_path = p_path where id = auth.uid();
end; $$;
revoke execute on function public.set_my_photo_path(text) from public, anon;
grant execute on function public.set_my_photo_path(text) to authenticated;
```

- [ ] **Step 2: Write a DB test**

Create `supabase/tests/photos_test.sql`:
```sql
begin;
select plan(2);
select ok(exists(select 1 from storage.buckets where id='profile-photos' and public=false),
  'private profile-photos bucket exists');
select ok(exists(select 1 from pg_proc where proname='set_my_photo_path'), 'setter exists');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; both assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0023_photos.sql supabase/tests/photos_test.sql
git commit -m "feat(p1.5): 0023 photo_path + private profile-photos bucket + owner RLS + setter"
```

---

### Task 2: Edge Function `sign-photo` (gated, short-lived signed URL)

**Files:**
- Create: `supabase/functions/sign-photo/index.ts`

- [ ] **Step 1: Write the function**

Create `supabase/functions/sign-photo/index.ts`:
```ts
import { createClient } from "jsr:@supabase/supabase-js@2";

// Mints a 60s signed URL for a TARGET user's photo, if the caller is allowed to see it.
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { target_id } = await req.json();
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Gate: target exists, not soft-deleted, and no block in either direction.
  const { data: prof } = await admin.from("profiles")
    .select("photo_path,soft_deleted_at").eq("id", target_id).maybeSingle();
  if (!prof?.photo_path || prof.soft_deleted_at) {
    return new Response(JSON.stringify({ url: null }), { headers: { "Content-Type": "application/json" } });
  }
  const { count } = await admin.from("blocks").select("*", { count: "exact", head: true })
    .or(`and(blocker_id.eq.${user.id},blocked_id.eq.${target_id}),and(blocker_id.eq.${target_id},blocked_id.eq.${user.id})`);
  if ((count ?? 0) > 0) return new Response(JSON.stringify({ url: null }), { status: 403 });

  const { data: signed } = await admin.storage.from("profile-photos")
    .createSignedUrl(prof.photo_path, 60);
  return new Response(JSON.stringify({ url: signed?.signedUrl ?? null }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

- [ ] **Step 2: Serve + smoke**

Run: `supabase functions serve sign-photo --env-file supabase/functions/.env`. With a user JWT + a `target_id` that has a `photo_path`, expect `{url}`; with a blocked pair expect 403; with no photo expect `{url:null}`.

- [ ] **Step 3: Commit**

```
git add supabase/functions/sign-photo/index.ts
git commit -m "feat(p1.5): sign-photo Edge Function (gated 60s signed URL for others' photos)"
```

---

### Task 3: PhotoRepository + providers

**Files:**
- Modify: `pubspec.yaml` (image_picker)
- Create: `lib/features/photos/data/photo_repository.dart`, `lib/features/photos/application/photo_providers.dart`
- Test: `test/features/photos/photo_repository_test.dart`

- [ ] **Step 1: Add image_picker + write the failing test**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub add image_picker`
Create `test/features/photos/photo_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  test('signedPhotoFor invokes sign-photo and returns the url', () async {
    final client = _MockClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('sign-photo', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {'url': 'https://signed/x'}, status: 200));
    final url = await PhotoRepository(client).signedPhotoFor('u2');
    expect(url, 'https://signed/x');
    verify(() => fns.invoke('sign-photo', body: {'target_id': 'u2'})).called(1);
  });

  test('setMyPhotoPath calls set_my_photo_path', () async {
    final client = _MockClient();
    when(() => client.rpc('set_my_photo_path', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await PhotoRepository(client).setMyPhotoPath('u1/avatar.jpg');
    verify(() => client.rpc('set_my_photo_path', params: {'p_path': 'u1/avatar.jpg'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/photos/photo_repository_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement repo + providers**

Create `lib/features/photos/data/photo_repository.dart`:
```dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoRepository {
  PhotoRepository(this._client);
  final SupabaseClient _client;

  Future<void> uploadMyPhoto(Uint8List bytes) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/avatar.jpg';
    await _client.storage.from('profile-photos').uploadBinary(
      path, bytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    await setMyPhotoPath(path);
  }

  Future<void> setMyPhotoPath(String path) =>
      _client.rpc('set_my_photo_path', params: {'p_path': path});

  /// Signed URL for another user's photo (gated server-side). Null if none/blocked.
  Future<String?> signedPhotoFor(String targetId) async {
    final res = await _client.functions.invoke('sign-photo', body: {'target_id': targetId});
    return (res.data as Map?)?['url'] as String?;
  }
}
```

Create `lib/features/photos/application/photo_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/photo_repository.dart';

final photoRepositoryProvider =
    Provider((ref) => PhotoRepository(ref.watch(supabaseClientProvider)));

/// Signed photo URL for a given user id (null = show monogram).
final signedPhotoProvider = FutureProvider.family<String?, String>(
    (ref, userId) => ref.watch(photoRepositoryProvider).signedPhotoFor(userId));
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/photos/photo_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```
git add pubspec.yaml pubspec.lock lib/features/photos/ test/features/photos/photo_repository_test.dart
git commit -m "feat(p1.5): PhotoRepository (upload own + gated signed URL for others) + providers"
```

---

### Task 4: Photo upload in onboarding/profile (optional)

**Files:**
- Create: `lib/features/photos/presentation/photo_upload_button.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_flow.dart` (an optional photo step) and the Profile/edit screen
- Test: `test/features/photos/photo_upload_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/photos/photo_upload_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:typed_data';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';
import 'package:cung_hat/features/photos/presentation/photo_upload_button.dart';

class _MockRepo extends Mock implements PhotoRepository {}

void main() {
  testWidgets('uploads the picked bytes', (tester) async {
    final repo = _MockRepo();
    when(() => repo.uploadMyPhoto(any())).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [photoRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: Scaffold(body: PhotoUploadButton(
        // injected picker returns fixed bytes so the test is deterministic
        pickBytes: () async => Uint8List.fromList([1, 2, 3]),
      ))),
    ));
    await tester.tap(find.byKey(const Key('upload_photo_btn')));
    await tester.pump();
    verify(() => repo.uploadMyPhoto(any())).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/photos/photo_upload_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement the button (picker injectable for testability)**

Create `lib/features/photos/presentation/photo_upload_button.dart`:
```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../application/photo_providers.dart';

class PhotoUploadButton extends ConsumerWidget {
  const PhotoUploadButton({super.key, this.pickBytes});
  /// Override in tests; defaults to the gallery picker.
  final Future<Uint8List?> Function()? pickBytes;

  Future<Uint8List?> _defaultPick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    return x == null ? null : x.readAsBytes();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      key: const Key('upload_photo_btn'),
      icon: const Icon(Icons.add_a_photo),
      label: const Text('Thêm ảnh (tùy chọn)'),
      onPressed: () async {
        final bytes = await (pickBytes ?? _defaultPick)();
        if (bytes != null) await ref.read(photoRepositoryProvider).uploadMyPhoto(bytes);
      },
    );
  }
}
```
Add this button as an **optional** step in `onboarding_flow.dart` (skippable) and on the Profile/edit screen.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/photos/photo_upload_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/photos/presentation/ lib/features/onboarding/ test/features/photos/photo_upload_test.dart
git commit -m "feat(p1.5): optional photo upload button (onboarding + profile)"
```

---

### Task 5: Show photos on the deck card + kèo roster (monogram fallback) + acceptance

**Files:**
- Create: `lib/features/photos/presentation/signed_avatar.dart`
- Modify: `lib/features/discovery/presentation/candidate_card.dart`, `lib/features/keo/presentation/keo_detail_screen.dart`
- Test: `test/features/photos/signed_avatar_test.dart`

- [ ] **Step 1: Write the failing test (falls back to monogram when url is null)**

Create `test/features/photos/signed_avatar_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/presentation/signed_avatar.dart';

void main() {
  testWidgets('shows monogram when signed url is null', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [signedPhotoProvider('u2').overrideWith((ref) async => null)],
      child: const MaterialApp(home: Scaffold(body: SignedAvatar(userId: 'u2', name: 'Linh'))),
    ));
    await tester.pump();
    expect(find.text('L'), findsOneWidget); // monogram fallback
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/photos/signed_avatar_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement SignedAvatar + use it**

Create `lib/features/photos/presentation/signed_avatar.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/photo_providers.dart';

class SignedAvatar extends ConsumerWidget {
  const SignedAvatar({super.key, required this.userId, required this.name, this.size = 96});
  final String userId;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mono = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final fallback = Container(
      width: size, height: size, alignment: Alignment.center,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Text(mono, style: TextStyle(fontSize: size * 0.5)),
    );
    return ref.watch(signedPhotoProvider(userId)).maybeWhen(
      data: (url) => url == null
          ? fallback
          : Image.network(url, width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback),
      orElse: () => fallback,
    );
  }
}
```
Use `SignedAvatar(userId: candidate.id, name: candidate.displayName ?? '')` in `CandidateCard` (replacing the inline monogram block) and in the `keo_detail_screen` roster rows.

- [ ] **Step 4: Run test + full suite + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: all green; `No issues found!` (the P1 `candidate_card_test` monogram test still passes because no photo → null → monogram).

- [ ] **Step 5: Acceptance**

Log in, upload a photo in onboarding/profile → object lands under `profile-photos/{uid}/avatar.jpg` (private; verify it is NOT publicly fetchable). As another user, the deck card / kèo roster shows that photo via a 60s signed URL; a user with no photo shows the monogram; a blocked pair gets no photo (403 → monogram). Confirm direct (unsigned) bucket access is denied.

- [ ] **Step 6: Commit**

```
git add lib/features/photos/presentation/signed_avatar.dart lib/features/discovery/ lib/features/keo/ test/features/photos/signed_avatar_test.dart
git commit -m "feat(p1.5): SignedAvatar (signed photo + monogram fallback) on card + roster + acceptance"
```

---

## Self-Review (completed by author)

- **Spec coverage:** optional private photos ✓ (T1 bucket+RLS, T4 upload); stored as path in private `{uid}/` bucket ✓ (T1,T3); others' photos only via short-lived **server-minted** signed URLs ✓ (T2 `sign-photo`, T5); monogram fallback preserved ✓ (T5). Closes the spec↔plan gap found in the verification pass.
- **Placeholder scan:** none — every code step is concrete; the picker is injectable for deterministic tests. No undefined symbols.
- **Type consistency:** RPC `set_my_photo_path` identical SQL↔Dart; Edge fn `sign-photo` name identical across `functions.invoke` and the dir; `PhotoRepository` method set (`uploadMyPhoto/setMyPhotoPath/signedPhotoFor`) consistent T3↔T4↔T5; `signedPhotoProvider.family<String?,String>(userId)` identical across T5 widgets and tests; reuses P0 `profiles`, P1 `blocks`/`CandidateCard`, P3 `KeoMember`/roster. Migration `0023` is dependency-free (no other migration references `photo_path`), so ordering is safe.

---

## Note
This plan was added during the verification pass to close the optional-photos gap. The full set is now **P0, P0.2, P0.3, P1, P1.5, P2, P3, P4, P5, P6, P7** (migrations 0001–0023).
