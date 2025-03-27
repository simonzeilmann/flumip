BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ALTER COLUMN "smtpServer" SET DEFAULT ''::text;
ALTER TABLE "settings" ALTER COLUMN "smtpFrom" SET DEFAULT 'flumip@yourdomain.com'::text;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250327205237438', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250327205237438', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
