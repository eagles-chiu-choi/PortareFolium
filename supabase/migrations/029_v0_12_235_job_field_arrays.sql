-- 029 · v0.12.235 · 직무 분야 배열 schema 보정
-- 포스트와 포트폴리오의 다중 직무 분야 저장 및 containment 조회 지원

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'posts'
          AND column_name = 'job_field'
          AND data_type = 'text'
    ) THEN
        ALTER TABLE public.posts
            ALTER COLUMN job_field TYPE TEXT[]
            USING CASE
                WHEN job_field IS NULL THEN NULL
                ELSE ARRAY[job_field]
            END;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'portfolio_items'
          AND column_name = 'job_field'
          AND data_type = 'text'
    ) THEN
        ALTER TABLE public.portfolio_items
            ALTER COLUMN job_field TYPE TEXT[]
            USING CASE
                WHEN job_field IS NULL THEN NULL
                ELSE ARRAY[job_field]
            END;
    END IF;
END $$;

INSERT INTO site_config (key, value)
VALUES ('db_schema_version', '"0.12.235"')
ON CONFLICT (key) DO UPDATE SET value = '"0.12.235"';
