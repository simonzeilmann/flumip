BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ALTER COLUMN "baseDir" SET DEFAULT '/opt/flumip'::text;
ALTER TABLE "settings" ALTER COLUMN "projectDir" SET DEFAULT '/opt/flumip/projects'::text;
ALTER TABLE "settings" ALTER COLUMN "geneDir" SET DEFAULT '/opt/flumip/genes'::text;
ALTER TABLE "settings" ALTER COLUMN "mipgenExecutable" SET DEFAULT '/opt/flumip/MIPGEN/mipgen'::text;
ALTER TABLE "settings" ALTER COLUMN "exonExtractScript" SET DEFAULT '/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh'::text;
ALTER TABLE "settings" ALTER COLUMN "ucscTrackGenerator" SET DEFAULT '/opt/flumip/MIPGEN/tools/generate_ucsc_track.py'::text;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250320092309850', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250320092309850', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
