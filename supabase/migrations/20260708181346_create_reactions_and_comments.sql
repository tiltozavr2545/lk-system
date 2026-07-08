-- Both tables key off "can I see the post?" for visibility. Rather than
-- re-deriving the author-or-connection check here, we lean on the fact
-- that posts already has its own RLS SELECT policy: a subquery against
-- posts run as the current user is filtered by that policy for free, so
-- `exists (select 1 from posts where id = ...)` is exactly "can I see it".

create table public.reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint reactions_one_per_user_per_post unique (post_id, user_id)
);

alter table public.reactions enable row level security;

create policy "Reactions are viewable by anyone who can see the post"
on public.reactions for select
to authenticated
using (exists (select 1 from posts p where p.id = reactions.post_id));

create policy "Users can like posts they can see"
on public.reactions for insert
to authenticated
with check (
  user_id = auth.uid()
  and exists (select 1 from posts p where p.id = reactions.post_id)
);

create policy "Users can remove their own like"
on public.reactions for delete
to authenticated
using (user_id = auth.uid());

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.users (id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create index comments_post_id_idx on public.comments (post_id);

alter table public.comments enable row level security;

create policy "Comments are viewable by anyone who can see the post"
on public.comments for select
to authenticated
using (exists (select 1 from posts p where p.id = comments.post_id));

create policy "Users can comment on posts they can see"
on public.comments for insert
to authenticated
with check (
  author_id = auth.uid()
  and exists (select 1 from posts p where p.id = comments.post_id)
);
