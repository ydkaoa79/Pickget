create or replace function public.sync_post_likes_count(target_post_id text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  synced_count integer;
begin
  select count(*)::integer
    into synced_count
    from public.likes
   where post_id::text = target_post_id;

  update public.posts
     set likes_count = synced_count
   where id::text = target_post_id;

  return synced_count;
end;
$$;

grant execute on function public.sync_post_likes_count(text) to authenticated;

create or replace function public.sync_comments_count(target_post_id text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  synced_count integer;
begin
  select count(*)::integer
    into synced_count
    from public.comments
   where post_id::text = target_post_id;

  update public.posts
     set comments_count = synced_count
   where id::text = target_post_id;

  return synced_count;
end;
$$;

grant execute on function public.sync_comments_count(text) to authenticated;
