BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "gene" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "genome" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL DEFAULT ''::text,
    "path" text,
    "fastaPath" text,
    "refPath" text,
    "snpFolder" text,
    "snp" json,
    "category" text,
    "active" boolean NOT NULL DEFAULT true,
    "indexed" boolean NOT NULL DEFAULT false,
    "indexing" boolean NOT NULL DEFAULT false,
    "indexPID" bigint NOT NULL DEFAULT 0,
    "indexResults" text NOT NULL DEFAULT ''::text
);

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" DROP COLUMN "gene";
ALTER TABLE "project" ADD COLUMN "genome" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "project_options" DROP COLUMN "fasta";
ALTER TABLE "project_options" DROP COLUMN "snp";
--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" DROP COLUMN "geneDir";
ALTER TABLE "settings" ADD COLUMN "genomeDir" text NOT NULL DEFAULT '/opt/flumip/data/genomes'::text;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250326090913467', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250326090913467', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
