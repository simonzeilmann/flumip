BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ALTER COLUMN "settingsPassword" DROP NOT NULL;
ALTER TABLE "settings" ALTER COLUMN "settingsPassword" DROP DEFAULT;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260924062414174', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924062414174', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
