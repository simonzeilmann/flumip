BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "customSnpDir" text NOT NULL DEFAULT '/opt/flumip/data/custom_snp'::text;
ALTER TABLE "settings" ALTER COLUMN "geneDir" SET DEFAULT '/opt/flumip/data/genes'::text;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250324152523947', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250324152523947', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
