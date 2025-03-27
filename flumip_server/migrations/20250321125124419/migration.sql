BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "gene" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL DEFAULT ''::text,
    "path" text NOT NULL,
    "fastaPath" text NOT NULL,
    "refPath" text NOT NULL,
    "snpFolder" text NOT NULL,
    "snp" json,
    "category" text NOT NULL,
    "active" boolean NOT NULL DEFAULT true,
    "indexed" boolean NOT NULL DEFAULT false,
    "indexing" boolean NOT NULL DEFAULT false,
    "indexPID" bigint NOT NULL DEFAULT 0,
    "indexResults" text NOT NULL DEFAULT ''::text
);

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" ADD COLUMN "gene" bigint;
ALTER TABLE "project" ADD COLUMN "snp" bigint;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "snp" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL DEFAULT ''::text,
    "vcfPath" text NOT NULL,
    "tbiPath" text NOT NULL,
    "folder" text NOT NULL,
    "active" boolean NOT NULL,
    "private" boolean NOT NULL DEFAULT false
);


--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250321125124419', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250321125124419', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
