BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" DROP COLUMN "ucscTrackGenerator";
ALTER TABLE "settings" DROP COLUMN "binCreationScript";

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20261006090028483', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261006090028483', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
