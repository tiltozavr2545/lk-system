-- Creates the public.users row synchronously with auth.users, regardless of
-- whether email confirmation is pending (i.e. before any session/JWT
-- exists). Client-side insert right after signUp() was racing against
-- "confirm email" and got rejected by RLS when no session existed yet.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', 'Без имени'));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Profile rows are now created exclusively by the trigger above.
drop policy "Users can insert their own profile" on public.users;
