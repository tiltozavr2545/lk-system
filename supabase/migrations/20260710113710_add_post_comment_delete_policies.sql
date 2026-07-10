-- Users can delete their own posts and comments. Deleting a post cascades
-- to its comments/reactions via the existing FK `on delete cascade`, but
-- the post's photo (if any) lives in Storage, not Postgres, so it needs
-- its own DELETE policy — mirrors the upload policy in
-- 20260708172235_storage_post_photo_policies.sql.

create policy "Users can delete their own posts"
on public.posts for delete
to authenticated
using (author_id = auth.uid());

create policy "Users can delete their own comments"
on public.comments for delete
to authenticated
using (author_id = auth.uid());

create policy "Users can delete their own post photos"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'media'
  and (storage.foldername(name))[1] = 'posts'
  and (storage.foldername(name))[2] = auth.uid()::text
);
