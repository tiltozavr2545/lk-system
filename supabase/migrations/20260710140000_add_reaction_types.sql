-- Reactions started life as a plain "like": one row per user per post, no
-- type. We now support three mutually-exclusive reaction types — like,
-- neutral, dislike. The existing unique (post_id, user_id) constraint already
-- enforces "one reaction per user per post", so a single type column is all
-- that's needed to turn the like into a pick-one triad. Existing rows are all
-- likes, which the default backfills.
alter table public.reactions
  add column type text not null default 'like'
  check (type in ('like', 'neutral', 'dislike'));

-- Switching reaction (e.g. like -> dislike) upserts onto the existing row via
-- ON CONFLICT DO UPDATE, which RLS gates behind an UPDATE policy. The existing
-- select/insert/delete policies still cover the other paths.
create policy "Users can change their own reaction"
on public.reactions for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
