-- 1. likes 테이블에 주민번호 칸 추가
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='likes' AND column_name='user_internal_id') THEN
        ALTER TABLE likes ADD COLUMN user_internal_id UUID;
    END IF;
END $$;

-- 2. bookmarks 테이블에 주민번호 칸 추가
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookmarks' AND column_name='user_internal_id') THEN
        ALTER TABLE bookmarks ADD COLUMN user_internal_id UUID;
    END IF;
END $$;

-- 3. follows 테이블에 주민번호 칸 추가 (팔로워/팔로잉 둘 다!)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='follows' AND column_name='follower_internal_id') THEN
        ALTER TABLE follows ADD COLUMN follower_internal_id UUID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='follows' AND column_name='following_internal_id') THEN
        ALTER TABLE follows ADD COLUMN following_internal_id UUID;
    END IF;
END $$;

-- 4. 기존 데이터 주민번호로 채워넣기 (user_profiles와 매칭)
UPDATE likes l SET user_internal_id = p.id FROM user_profiles p WHERE l.user_id = p.user_id AND l.user_internal_id IS NULL;
UPDATE bookmarks b SET user_internal_id = p.id FROM user_profiles p WHERE b.user_id = p.user_id AND b.user_internal_id IS NULL;
UPDATE follows f SET follower_internal_id = p.id FROM user_profiles p WHERE f.follower_id = p.user_id AND f.follower_internal_id IS NULL;
UPDATE follows f SET following_internal_id = p.id FROM user_profiles p WHERE f.following_id = p.user_id AND f.following_internal_id IS NULL;
UPDATE comments c SET user_internal_id = p.id FROM user_profiles p WHERE c.user_id = p.user_id AND c.user_internal_id IS NULL;
