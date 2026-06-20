# Cùng Hát — P2 Chat (1-1 Realtime) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Matched users chat 1-1 in realtime via **Broadcast-from-Database on private channels** (never Postgres Changes), with unread badges, outbound + inbound message-safety, and a "Lập kèo" promotion hook from a 1-1 thread.

**Architecture:** Builds on P1. Migration `0009` adds `messages` + `message_reads`, a `send_message` RPC (membership-checked + rate-limited), and an `AFTER INSERT` trigger that calls `realtime.send(... private := true)` on topic `match:{id}`. Subscription is gated by an RLS policy on `realtime.messages` that joins the topic id back to `matches` membership — the topic name is a security artifact. Flutter adds a `chat` feature (repository → providers → screens) plus a shared hidden-words `message_safety` util.

**Tech Stack:** Supabase Realtime (Broadcast-from-DB), SECURITY DEFINER RPCs, RLS on `realtime.messages`, Riverpod 3 (StreamProvider), freezed, mocktail.

**Depends on:** P1 (`matches`, `record_swipe`, `enforce_rate_limit`, `blocks`), P0 (RPC pattern, `supabaseClientProvider`), app shell tab 2 = "Chat".

---

### Task 1: Migration 0009 — messages, reads, send RPC, broadcast trigger, realtime RLS

**Files:**
- Create: `supabase/migrations/0009_chat.sql`, `supabase/tests/chat_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0009_chat.sql`:
```sql
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_type text not null check (thread_type in ('match','keo')),
  thread_id uuid not null,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  soft_deleted_at timestamptz
);
create index messages_thread_ix on public.messages(thread_type, thread_id, created_at);
alter table public.messages enable row level security;

-- Helper: is the caller a participant of this match thread?
create or replace function app_private.in_match(p_thread uuid)
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.matches m
                 where m.id = p_thread and m.status='active'
                   and (m.user_a = auth.uid() or m.user_b = auth.uid()));
$$;

-- Read own threads' messages (participant only). Inserts go through send_message RPC only.
create policy messages_select_participant on public.messages for select
  using (thread_type='match' and app_private.in_match(thread_id));

create table public.message_reads (
  thread_type text not null,
  thread_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (thread_type, thread_id, user_id)
);
alter table public.message_reads enable row level security;
create policy message_reads_self on public.message_reads for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- Broadcast each insert to the private topic match:{id}
create or replace function app_private.broadcast_message()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  perform realtime.send(
    jsonb_build_object('id', new.id, 'thread_id', new.thread_id,
      'sender_id', new.sender_id, 'body', new.body, 'created_at', new.created_at),
    'new_message',
    new.thread_type || ':' || new.thread_id::text,
    true   -- private channel
  );
  return new;
end; $$;
create trigger messages_broadcast after insert on public.messages
  for each row execute function app_private.broadcast_message();

-- Send (membership-checked + rate-limited)
create or replace function public.send_message(p_thread uuid, p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare mid uuid;
begin
  if not app_private.in_match(p_thread) then
    raise exception 'not_a_member' using errcode='check_violation';
  end if;
  perform app_private.enforce_rate_limit('message', 60, interval '1 minute');
  insert into public.messages(thread_type, thread_id, sender_id, body)
  values ('match', p_thread, auth.uid(), p_body) returning id into mid;
  return mid;
end; $$;

create or replace function public.mark_match_read(p_thread uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('match', p_thread, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;

revoke execute on function public.send_message(uuid,text) from public, anon;
revoke execute on function public.mark_match_read(uuid) from public, anon;
grant execute on function public.send_message(uuid,text) to authenticated;
grant execute on function public.mark_match_read(uuid) to authenticated;

-- Realtime authorization: only match members may receive on the private topic.
create policy "match members receive broadcasts"
  on realtime.messages for select to authenticated
  using (
    exists (select 1 from public.matches m
            where 'match:' || m.id::text = realtime.topic()
              and m.status='active'
              and (m.user_a = auth.uid() or m.user_b = auth.uid()))
  );
```

- [ ] **Step 2: Write a DB test (non-member cannot send)**

Create `supabase/tests/chat_test.sql`:
```sql
begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='send_message'), 'send_message exists');
set local role authenticated;
-- with no auth.uid()/match, sending must fail membership check
select throws_ok(
  $$ select public.send_message('00000000-0000-0000-0000-000000000000'::uuid, 'hi') $$,
  'check_violation', null, 'non-member cannot send');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0009_chat.sql supabase/tests/chat_test.sql
git commit -m "feat(p2): 0009 chat (messages/reads + send RPC + broadcast trigger + realtime RLS)"
```

---

### Task 2: Message model + ChatRepository + providers

**Files:**
- Create: `lib/features/chat/domain/message.dart`, `lib/features/chat/data/chat_repository.dart`, `lib/features/chat/application/chat_providers.dart`
- Test: `test/features/chat/chat_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/chat_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('sendMessage calls send_message RPC with thread + body', () async {
    final client = _MockClient();
    when(() => client.rpc('send_message', params: any(named: 'params')))
        .thenAnswer((_) async => 'm1');
    await ChatRepository(client).sendMessage('t1', 'hello');
    verify(() => client.rpc('send_message',
        params: {'p_thread': 't1', 'p_body': 'hello'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/chat/chat_repository_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Implement model, repo, providers**

Create `lib/features/chat/domain/message.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    @JsonKey(name: 'thread_id') required String threadId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String body,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Message;
  factory Message.fromJson(Map<String, dynamic> j) => _$MessageFromJson(j);
}
```

Create `lib/features/chat/data/chat_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/message.dart';

class ChatRepository {
  ChatRepository(this._client);
  final SupabaseClient _client;

  Future<String> sendMessage(String threadId, String body) async {
    final id = await _client.rpc('send_message',
        params: {'p_thread': threadId, 'p_body': body});
    return id as String;
  }

  Future<void> markRead(String threadId) =>
      _client.rpc('mark_match_read', params: {'p_thread': threadId});

  Future<List<Message>> history(String threadId) async {
    final rows = await _client
        .from('messages').select()
        .eq('thread_type', 'match').eq('thread_id', threadId)
        .order('created_at');
    return (rows as List).map((e) => Message.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Live messages on the private topic match:{threadId}.
  Stream<Message> subscribe(String threadId) {
    final ch = _client.channel('match:$threadId', opts: const RealtimeChannelConfig(private: true));
    late final Stream<Message> stream;
    final controller = StreamController<Message>();
    ch.onBroadcast(event: 'new_message', callback: (payload) {
      controller.add(Message.fromJson(Map<String, dynamic>.from(payload)));
    }).subscribe();
    controller.onCancel = () => _client.removeChannel(ch);
    stream = controller.stream;
    return stream;
  }
}
```
Add `import 'dart:async';` at the top.

Create `lib/features/chat/application/chat_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/chat_repository.dart';
import '../domain/message.dart';

final chatRepositoryProvider =
    Provider((ref) => ChatRepository(ref.watch(supabaseClientProvider)));

final messageHistoryProvider = FutureProvider.family<List<Message>, String>(
    (ref, threadId) => ref.watch(chatRepositoryProvider).history(threadId));

final liveMessagesProvider = StreamProvider.family<Message, String>((ref, threadId) {
  final sub = ref.watch(chatRepositoryProvider).subscribe(threadId);
  ref.keepAlive(); // do not auto-pause an open chat
  return sub;
});
```

- [ ] **Step 4: Generate + run test**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/chat/chat_repository_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/chat/ test/features/chat/chat_repository_test.dart
git commit -m "feat(p2): Message model + ChatRepository (send/read/history/subscribe) + providers"
```

---

### Task 3: Message-safety util (hidden words, EN+VI)

**Files:**
- Create: `lib/core/utils/message_safety.dart`
- Test: `test/core/message_safety_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/message_safety_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/utils/message_safety.dart';

void main() {
  test('flags risky outbound phrases', () {
    expect(messageLooksUnsafe('cho mình xin số tài khoản'), isTrue);
    expect(messageLooksUnsafe('send me your bank account'), isTrue);
  });
  test('passes normal chat', () {
    expect(messageLooksUnsafe('Tối nay đi hát nhé?'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/message_safety_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

Create `lib/core/utils/message_safety.dart`:
```dart
const _riskyPatterns = <String>[
  'số tài khoản', 'tài khoản ngân hàng', 'chuyển khoản', 'mã otp', 'vay tiền',
  'bank account', 'send money', 'transfer', 'otp code', 'crypto',
];

bool messageLooksUnsafe(String text) {
  final t = text.toLowerCase();
  return _riskyPatterns.any(t.contains);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/message_safety_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/core/utils/message_safety.dart test/core/message_safety_test.dart
git commit -m "feat(p2): message-safety hidden-words util (EN+VI)"
```

---

### Task 4: Chat thread screen (list + composer + realtime)

**Files:**
- Create: `lib/features/chat/presentation/chat_screen.dart`
- Modify: `lib/app/router.dart` (route `/chat/:matchId`)
- Test: `test/features/chat/chat_screen_test.dart`

- [ ] **Step 1: Write the failing widget test (composer send + outbound safety)**

Create `test/features/chat/chat_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';

class _MockRepo extends Mock implements ChatRepository {}

void main() {
  testWidgets('typing a safe message and sending calls sendMessage', (tester) async {
    final repo = _MockRepo();
    when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
    when(() => repo.subscribe(any())).thenAnswer((_) => const Stream<Message>.empty());
    when(() => repo.markRead(any())).thenAnswer((_) async {});
    when(() => repo.sendMessage(any(), any())).thenAnswer((_) async => 'm1');
    await tester.pumpWidget(ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ChatScreen(matchId: 't1', otherName: 'Linh')),
    ));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'đi hát nhé');
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();
    verify(() => repo.sendMessage('t1', 'đi hát nhé')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/chat/chat_screen_test.dart`
Expected: FAIL — `chat_screen.dart` not found.

- [ ] **Step 3: Implement ChatScreen**

Create `lib/features/chat/presentation/chat_screen.dart` — a `ConsumerStatefulWidget(matchId, otherName)` that: loads `messageHistoryProvider(matchId)`, listens to `liveMessagesProvider(matchId)` appending new messages, renders a `ListView` of bubbles (sender vs other), and a composer `TextField` + send `IconButton(key: Key('send_btn'))`. On send: if `messageLooksUnsafe(text)` show an AlertDialog "Gửi tin này?" (Hủy / Gửi); otherwise call `ref.read(chatRepositoryProvider).sendMessage(matchId, text)`; call `markRead` on open. Include a "Lập kèo" button in the AppBar (Task 6).

In `lib/app/router.dart` add: `GoRoute(path: '/chat/:matchId', builder: (_, s) => ChatScreen(matchId: s.pathParameters['matchId']!, otherName: s.uri.queryParameters['name'] ?? ''))`.

- [ ] **Step 4: Run test + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/chat/chat_screen_test.dart
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```
git add lib/features/chat/presentation/chat_screen.dart lib/app/router.dart test/features/chat/chat_screen_test.dart
git commit -m "feat(p2): 1-1 chat screen (history + realtime + outbound safety)"
```

---

### Task 5: Matches/inbox list (Chat tab) + unread

**Files:**
- Create: `lib/features/chat/data/match_inbox.dart`, `lib/features/chat/presentation/inbox_screen.dart`
- Modify: `lib/app/home_shell.dart` (tab 2 → InboxScreen)
- Test: `test/features/chat/inbox_test.dart`

- [ ] **Step 1: Write the failing test (repo lists my matches)**

Create `test/features/chat/inbox_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('myMatches calls the get_my_matches RPC', () async {
    final client = _MockClient();
    when(() => client.rpc('get_my_matches')).thenAnswer((_) async => [
      {'match_id': 't1', 'other_id': 'u2', 'other_name': 'Linh', 'unread': 2},
    ]);
    final list = await MatchInbox(client).myMatches();
    expect(list.single.otherName, 'Linh');
    expect(list.single.unread, 2);
  });
}
```

- [ ] **Step 2: Add the RPC migration + run failing test**

Create `supabase/migrations/0010_inbox.sql`:
```sql
create type public.match_summary as (match_id uuid, other_id uuid, other_name text, unread int);
create or replace function public.get_my_matches()
returns setof public.match_summary language sql security definer set search_path='' as $$
  select m.id,
    case when m.user_a = auth.uid() then m.user_b else m.user_a end as other_id,
    (select display_name from public.profiles p
       where p.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end) as other_name,
    (select count(*)::int from public.messages msg
       where msg.thread_type='match' and msg.thread_id = m.id
         and msg.sender_id <> auth.uid()
         and msg.created_at > coalesce(
           (select last_read_at from public.message_reads r
             where r.thread_type='match' and r.thread_id=m.id and r.user_id=auth.uid()),
           'epoch')) as unread
  from public.matches m
  where m.status='active' and (m.user_a=auth.uid() or m.user_b=auth.uid())
  order by m.created_at desc;
$$;
revoke execute on function public.get_my_matches() from public, anon;
grant execute on function public.get_my_matches() to authenticated;
```
Run: `supabase db reset` then `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/chat/inbox_test.dart`
Expected: migration applies; test FAILS (MatchInbox not found).

- [ ] **Step 3: Implement MatchInbox + InboxScreen + wire tab 2**

Create `lib/features/chat/data/match_inbox.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchSummary {
  MatchSummary({required this.matchId, required this.otherId, required this.otherName, required this.unread});
  final String matchId; final String otherId; final String otherName; final int unread;
  factory MatchSummary.fromJson(Map<String, dynamic> j) => MatchSummary(
    matchId: j['match_id'] as String, otherId: j['other_id'] as String,
    otherName: (j['other_name'] ?? '') as String, unread: (j['unread'] ?? 0) as int);
}

class MatchInbox {
  MatchInbox(this._client);
  final SupabaseClient _client;
  Future<List<MatchSummary>> myMatches() async {
    final rows = await _client.rpc('get_my_matches');
    return (rows as List).map((e) => MatchSummary.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
```
Create `lib/features/chat/presentation/inbox_screen.dart` — a `ConsumerWidget` listing `MatchSummary`s (avatar monogram + name + unread badge) that navigates to `/chat/{matchId}?name={otherName}` on tap; provider `matchInboxProvider`/`inboxProvider` analogous to earlier features. Wire tab 2 of `home_shell.dart` to `const InboxScreen()`.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/chat/inbox_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add supabase/migrations/0010_inbox.sql lib/features/chat/ lib/app/home_shell.dart test/features/chat/inbox_test.dart
git commit -m "feat(p2): matches inbox (get_my_matches + unread) on Chat tab"
```

---

### Task 6: "Lập kèo" promotion hook + l10n + acceptance

**Files:**
- Modify: `lib/features/chat/presentation/chat_screen.dart` (AppBar action), `lib/l10n/*.arb`

- [ ] **Step 1: Add the promotion action (stub route to Kèo creation in P3)**

In `ChatScreen` AppBar add an action button labelled "Lập kèo" that, for now, navigates to `/keo/create` (the route is implemented in P3; until then it may show a "Sắp có" SnackBar). Add l10n keys `chatPromoteKeo`, `sendThisTitle`, `sendThisBody`, `cancel`, `send` to both ARBs and `gen-l10n`.

- [ ] **Step 2: Full suite + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test` then `... analyze`
Expected: all green; `No issues found!`.

- [ ] **Step 3: Acceptance — live 1-1 chat**

With two matched seed users (from P1 acceptance): open the match from the Chat tab on account A; send a message; confirm it appears on account B in realtime (second session) without reload; confirm unread badge increments on B's inbox and clears after open; try a risky phrase ("số tài khoản") → "Gửi tin này?" dialog appears.

- [ ] **Step 4: Commit**

```
git add lib/features/chat/ lib/l10n/
git commit -m "feat(p2): Lập kèo promotion hook + chat l10n + P2 acceptance"
```

---

## Self-Review (completed by author)

- **Spec coverage:** Broadcast-from-DB on private channels ✓ (T1 trigger + realtime RLS); 1-1 thread + history + realtime ✓ (T2,T4); unread badges ✓ (T5); outbound message-safety ✓ (T3,T4); membership-gated + rate-limited send ✓ (T1); "Lập kèo" promotion ✓ (T6). Inbound auto-blur of flagged received messages is deferred to the chat-polish pass (the util + outbound dialog ship here).
- **Placeholder scan:** the only forward reference is the `/keo/create` route used by the promotion hook (built in P3; guarded with a "Sắp có" SnackBar until then) — intentional and labelled. No undefined Dart symbols.
- **Type consistency:** RPC names `send_message`/`mark_match_read`/`get_my_matches` identical across SQL (T1,T5) and Dart (T2,T5); private topic string `match:{id}` identical in the broadcast trigger (T1), the realtime RLS policy (T1), and `ChatRepository.subscribe` (T2); `Message` JSON keys match the broadcast payload (`thread_id`, `sender_id`, `created_at`); `ChatRepository` method set consistent T2↔T4; `MatchSummary` fields match the `match_summary` SQL type.

---

## Next plans (when we reach them)
- **P3** Kèo board (create/list/request-to-join/host-approve/all-confirm + group chat reusing the Broadcast-from-DB pattern), **P4** venues/midpoint plan, **P5** compliance/moderation console, **P6** monetization (IAP digital goods + MoMo/ZaloPay venue commission), **P7** launch (3-city seeding, FCM push, store submission).
