BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ALTER COLUMN "maxProjectLifetimeDays" SET DEFAULT 14;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20261102131400074', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261102131400074', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
