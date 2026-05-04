-- PickGet RLS hardening script.
-- Run this in Supabase SQL Editor after taking a database backup.
-- Public reads are kept, but writes are limited to the signed-in owner.

begin;

alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.bookmarks enable row level security;
alter table public.comments enable row level security;
alter table public.votes enable row level security;
alter table public.follows enable row level security;
alter table public.points_history enable row level security;
alter table public.user_profiles enable row level security;

create or replace function public.is_post_owner(target_post_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.posts p
     where p.id = target_post_id
       and (
         p.uploader_internal_id::text = auth.uid()::text
         or p.uploader_id = auth.uid()::text
       )
  );
$$;

create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.user_profiles up
     where up.id::text = auth.uid()::text
       and up.role = 'admin'
  );
$$;

create or replace function public.can_view_post_discussion(target_post_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  post_is_expired boolean := false;
begin
  if auth.uid() is null then
    return false;
  end if;

  if public.is_admin_user() or public.is_post_owner(target_post_id) then
    return true;
  end if;

  if exists (
    select 1
      from public.votes v
     where v.post_id = target_post_id
       and v.user_internal_id = auth.uid()::text
  ) then
    return true;
  end if;

  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'posts'
       and column_name = 'is_expired'
  ) then
    execute 'select coalesce(is_expired, false) from public.posts where id = $1'
      into post_is_expired
      using target_post_id;
  end if;

  if not coalesce(post_is_expired, false) then
    select exists (
      select 1
        from public.posts p
       where p.id = target_post_id
         and now() >= p.created_at + (
           coalesce(
             (
               select split_part(tag, ':', 2)::integer
                 from unnest(coalesce(p.tags, array[]::text[])) as tag
                where tag ~ '^duration:[0-9]+$'
                limit 1
             ),
             1440
           ) * interval '1 minute'
         )
    )
    into post_is_expired;
  end if;

  return coalesce(post_is_expired, false);
end;
$$;

-- Remove broad/duplicate policies shown in the current project.
drop policy if exists "Allow all access" on public.posts;
drop policy if exists "Anyone can update posts" on public.posts;
drop policy if exists "Enable read access for all" on public.posts;
drop policy if exists "Enable write for authenticated" on public.posts;

drop policy if exists "Anyone can insert likes" on public.likes;
drop policy if exists "Anyone can delete likes" on public.likes;
drop policy if exists "Anyone can read likes" on public.likes;
drop policy if exists "Enable read access for all" on public.likes;
drop policy if exists "Enable write for authenticated" on public.likes;

drop policy if exists "Anyone can insert bookmarks" on public.bookmarks;
drop policy if exists "Anyone can delete bookmarks" on public.bookmarks;
drop policy if exists "Anyone can read bookmarks" on public.bookmarks;
drop policy if exists "Enable read access for all" on public.bookmarks;
drop policy if exists "Enable write for authenticated" on public.bookmarks;

drop policy if exists "Anyone can insert comments" on public.comments;
drop policy if exists "Anyone can update/delete" on public.comments;
drop policy if exists "Anyone can read comments" on public.comments;
drop policy if exists "Enable read access for all" on public.comments;
drop policy if exists "Enable write for authenticated" on public.comments;

drop policy if exists "기존 기능 유지" on public.votes;
drop policy if exists "Enable read access for all" on public.votes;
drop policy if exists "Enable write for authenticated" on public.votes;

drop policy if exists "Anyone can insert follows" on public.follows;
drop policy if exists "Anyone can delete follows" on public.follows;
drop policy if exists "Anyone can read follows" on public.follows;
drop policy if exists "Enable read access for all" on public.follows;
drop policy if exists "Enable write for authenticated" on public.follows;

drop policy if exists "Anyone can access points_history" on public.points_history;
drop policy if exists "Enable read access for all" on public.points_history;
drop policy if exists "Enable write for authenticated" on public.points_history;

drop policy if exists "Anyone can access user_profiles" on public.user_profiles;
drop policy if exists "Enable read access for all" on public.user_profiles;
drop policy if exists "Enable write for authenticated" on public.user_profiles;

-- Posts: anyone can read. Signed-in users can create/update/delete only their posts.
create policy "posts are publicly readable"
on public.posts for select
using (true);

create policy "users can create their own posts"
on public.posts for insert
to authenticated
with check (
  uploader_internal_id::text = auth.uid()::text
  or uploader_id = auth.uid()::text
);

create policy "users can update their own posts"
on public.posts for update
to authenticated
using (
  uploader_internal_id::text = auth.uid()::text
  or uploader_id = auth.uid()::text
  or public.is_admin_user()
)
with check (
  uploader_internal_id::text = auth.uid()::text
  or uploader_id = auth.uid()::text
  or public.is_admin_user()
);

create policy "users can delete their own posts"
on public.posts for delete
to authenticated
using (
  uploader_internal_id::text = auth.uid()::text
  or uploader_id = auth.uid()::text
  or public.is_admin_user()
);

-- Likes/bookmarks/follows: public read, owner-only writes.
create policy "likes are publicly readable"
on public.likes for select
using (true);

create policy "users can create their own likes"
on public.likes for insert
to authenticated
with check (
  user_id = auth.uid()::text
  or user_internal_id::text = auth.uid()::text
);

create policy "users can delete their own likes"
on public.likes for delete
to authenticated
using (
  user_id = auth.uid()::text
  or user_internal_id::text = auth.uid()::text
);

create policy "bookmarks are publicly readable"
on public.bookmarks for select
using (true);

create policy "users can create their own bookmarks"
on public.bookmarks for insert
to authenticated
with check (
  user_id = auth.uid()::text
  or user_internal_id::text = auth.uid()::text
);

create policy "users can delete their own bookmarks"
on public.bookmarks for delete
to authenticated
using (
  user_id = auth.uid()::text
  or user_internal_id::text = auth.uid()::text
);

create policy "follows are publicly readable"
on public.follows for select
using (true);

create policy "users can create their own follows"
on public.follows for insert
to authenticated
with check (
  follower_id = auth.uid()::text
  or follower_internal_id::text = auth.uid()::text
);

create policy "users can delete their own follows"
on public.follows for delete
to authenticated
using (
  follower_id = auth.uid()::text
  or follower_internal_id::text = auth.uid()::text
);

-- Comments: visible only after voting, to the post owner/admin, or to signed-in
-- users after a vote has ended. Comment owner can edit/delete. Post owner can
-- moderate.
create policy "comments are readable after pick or expiry"
on public.comments for select
to authenticated
using (public.can_view_post_discussion(post_id));

create policy "users can create their own comments"
on public.comments for insert
to authenticated
with check (
  user_internal_id::text = auth.uid()::text
  and public.can_view_post_discussion(post_id)
);

create policy "comment owners and post owners can update comments"
on public.comments for update
to authenticated
using (
  user_internal_id::text = auth.uid()::text
  or public.is_post_owner(post_id)
  or public.is_admin_user()
)
with check (
  user_internal_id::text = auth.uid()::text
  or public.is_post_owner(post_id)
  or public.is_admin_user()
);

create policy "comment owners and post owners can delete comments"
on public.comments for delete
to authenticated
using (
  user_internal_id::text = auth.uid()::text
  or public.is_post_owner(post_id)
  or public.is_admin_user()
);

-- Votes: raw vote rows are readable only after the viewer has picked, owns the
-- post, is an admin, or the vote has ended. Avoid direct edits.
create policy "votes are readable after pick or expiry"
on public.votes for select
to authenticated
using (public.can_view_post_discussion(post_id));

create policy "users can create their own votes"
on public.votes for insert
to authenticated
with check (
  user_internal_id = auth.uid()::text
);

-- Points: public totals can still come from user_profiles. History should be private.
create policy "users can read their own points history"
on public.points_history for select
to authenticated
using (
  user_id = auth.uid()::text
  or user_internal_id::text = auth.uid()::text
  or public.is_admin_user()
);

create policy "users can insert their own points history"
on public.points_history for insert
to authenticated
with check (
  user_id = auth.uid()::text
  or user_internal_id::text = auth.uid()::text
  or public.is_admin_user()
);

-- Profiles: public read for channel/profile display, owner-only writes.
create policy "profiles are publicly readable"
on public.user_profiles for select
using (true);

create policy "users can create their own profile"
on public.user_profiles for insert
to authenticated
with check (
  id::text = auth.uid()::text
  or user_id = auth.uid()::text
);

create policy "users can update their own profile"
on public.user_profiles for update
to authenticated
using (
  id::text = auth.uid()::text
  or user_id = auth.uid()::text
  or public.is_admin_user()
)
with check (
  id::text = auth.uid()::text
  or user_id = auth.uid()::text
  or public.is_admin_user()
);

commit;
