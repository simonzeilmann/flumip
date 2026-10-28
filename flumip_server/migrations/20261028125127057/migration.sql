BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" ADD COLUMN "keptIndefinitely" boolean NOT NULL DEFAULT false;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20261028125127057', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261028125127057', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
