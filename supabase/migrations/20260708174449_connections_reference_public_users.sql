-- Repoint both FKs at public.users (same values as auth.users, since
-- handle_new_user() creates one row per the other) so PostgREST can embed
-- the other side's name in a single query for the friends list:
-- .select('*, user_a:users!connections_user_a_id_fkey(name), user_b:users!connections_user_b_id_fkey(name)')
alter table public.connections drop constraint connections_user_a_id_fkey;
alter table public.connections
  add constraint connections_user_a_id_fkey foreign key (user_a_id) references public.users (id) on delete cascade;

alter table public.connections drop constraint connections_user_b_id_fkey;
alter table public.connections
  add constraint connections_user_b_id_fkey foreign key (user_b_id) references public.users (id) on delete cascade;
