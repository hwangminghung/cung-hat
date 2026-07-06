-- Run with: supabase test db
-- Proves migration 20260706130000_profile_prompts: set_my_prompts (replace-all,
-- max 3, CHECK char_length(answer) 1..120) and that get_my_profile() surfaces
-- the caller's prompts in position order.
begin;
select plan(5);

set local role postgres;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000d1')  -- caller
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('00000000-0000-0000-0000-0000000000d1','Prompter','1990-01-01', true)
  on conflict (id) do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d1","role":"authenticated"}';
set local role authenticated;

-- 1) set_my_prompts accepts 2 valid entries.
select lives_ok(
  $$ select public.set_my_prompts('[
       {"prompt_id":"p1","answer":"Em cua ngay hom qua"},
       {"prompt_id":"p2","answer":"Ballad"}
     ]'::jsonb) $$,
  'set_my_prompts accepts 2 valid prompt entries');

-- 2) get_my_profile() surfaces exactly 2 prompts, in insertion (position) order
--    (checked together: length=2 AND first element is p1, the one inserted first).
select ok(
  (select jsonb_array_length((public.get_my_profile()).prompts) = 2
      and (public.get_my_profile()).prompts -> 0 ->> 'prompt_id' = 'p1'),
  'get_my_profile prompts has 2 elements, in insertion order (p1 first)');

-- 3) more than 3 prompts -> check_violation (23514, "too_many_prompts").
select throws_ok(
  $$ select public.set_my_prompts('[
       {"prompt_id":"p1","answer":"a"},
       {"prompt_id":"p2","answer":"b"},
       {"prompt_id":"p3","answer":"c"},
       {"prompt_id":"p4","answer":"d"}
     ]'::jsonb) $$,
  '23514', 'too_many_prompts', '>3 prompts raises check_violation (too_many_prompts)');

-- 4) an answer over 120 chars -> table CHECK violation (23514).
select throws_ok(
  format(
    $$ select public.set_my_prompts('[{"prompt_id":"p1","answer":"%s"}]'::jsonb) $$,
    repeat('a', 121)
  ),
  '23514', null, '121-char answer raises check_violation (table CHECK)');

-- 5) replace-all semantics: setting again with 1 prompt leaves exactly 1 row.
select public.set_my_prompts('[{"prompt_id":"p3","answer":"Chi mot bai thoi"}]'::jsonb);
set local role postgres;
select is(
  (select count(*)::int from public.profile_prompts
     where user_id = '00000000-0000-0000-0000-0000000000d1'),
  1,
  'set_my_prompts replaces the whole set (1 row remains after re-set with 1 entry)');

select * from finish();
rollback;
