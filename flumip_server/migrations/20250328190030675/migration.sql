BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "binCreationScript" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/tools/add_bins_to_refgene.py'::text;
ALTER TABLE "settings" ADD COLUMN "bigGenePredToGenePredExecutable" text NOT NULL DEFAULT '/opt/flumip/tools/bigGenePredToGenePred'::text;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250328190030675', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250328190030675', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
