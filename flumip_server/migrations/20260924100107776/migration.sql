BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "snp" DROP COLUMN "active";

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260924100107776', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924100107776', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
