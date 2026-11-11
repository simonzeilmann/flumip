BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "guestSnpMaxMegabytes" bigint NOT NULL DEFAULT 10;
ALTER TABLE "settings" ADD COLUMN "guestMaxSnps" bigint NOT NULL DEFAULT 3;
ALTER TABLE "settings" ADD COLUMN "guestSnpRetentionDays" bigint NOT NULL DEFAULT 7;
ALTER TABLE "settings" ALTER COLUMN "demoModeRetentionHours" SET DEFAULT 48;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "snp" ADD COLUMN "expires" timestamp without time zone;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20261102124918359', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261102124918359', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
