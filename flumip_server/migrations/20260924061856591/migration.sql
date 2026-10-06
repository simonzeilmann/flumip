BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" DROP COLUMN "tags";

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260924061856591', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924061856591', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
