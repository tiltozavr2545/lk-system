-- 1) Comments should only be visible to the post's viewer if the commenter
-- is themself or one of the viewer's own Connections — not anyone who
-- happens to be able to see the post (e.g. a mutual friend of the author
-- who isn't a friend of the viewer). This is core to the app's premise:
-- you only see content from people you've actually met.
drop policy "Comments are viewable by anyone who can see the post" on public.comments;

create policy "Comments are viewable by the viewer's own connections"
on public.comments for select
to authenticated
using (
  exists (select 1 from posts p where p.id = comments.post_id)
  and (
    comments.author_id = auth.uid()
    or exists (
      select 1 from connections c
      where (c.user_a_id = auth.uid() and c.user_b_id = comments.author_id)
         or (c.user_b_id = auth.uid() and c.user_a_id = comments.author_id)
    )
  )
);

-- 2) Bucket-level guardrail against oversized/non-image uploads. Client
-- already downsizes post photos to maxWidth 1600, so this is a server-side
-- backstop, not the primary constraint — sized generously enough for an
-- uncompressed 4K photo rather than clamping to what the client sends today.
update storage.buckets
set file_size_limit = 20971520, -- 20 MiB
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
where id = 'media';

-- 3) Postgres grants EXECUTE on new functions to PUBLIC by default; the
-- original `grant ... to authenticated` never revoked that default, so
-- anon could call these too. Both functions already reject anon at
-- runtime (auth.uid() is null), so this was not exploitable, but the
-- grant should reflect the actual intent.
revoke execute on function public.create_invite_link() from public, anon;
revoke execute on function public.activate_invite_link(text) from public, anon;
grant execute on function public.create_invite_link() to authenticated;
grant execute on function public.activate_invite_link(text) to authenticated;

-- 4) A user may only have one unused invite link outstanding at a time.
-- The partial unique index is the actual guarantee (closes the race
-- between two concurrent calls); the function change below is what makes
-- that guarantee pleasant to hit instead of erroring.
create unique index invite_links_one_active_per_owner
on invite_links (owner_id)
where not is_used;

create or replace function public.create_invite_link()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code text;
  v_existing text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- Already have an unused invite? Hand back the same code instead of
  -- minting a new one (idempotent, and the client just displays whatever
  -- code comes back, so no app-side change needed).
  select code into v_existing
  from invite_links
  where owner_id = auth.uid() and not is_used
  limit 1;

  if v_existing is not null then
    return v_existing;
  end if;

  v_code := encode(gen_random_bytes(5), 'hex');

  insert into invite_links (owner_id, code)
  values (auth.uid(), v_code);

  return v_code;
end;
$$;
