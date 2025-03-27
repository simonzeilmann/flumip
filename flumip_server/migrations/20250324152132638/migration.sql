BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "gene" ALTER COLUMN "path" DROP NOT NULL;
ALTER TABLE "gene" ALTER COLUMN "fastaPath" DROP NOT NULL;
ALTER TABLE "gene" ALTER COLUMN "refPath" DROP NOT NULL;
ALTER TABLE "gene" ALTER COLUMN "snpFolder" DROP NOT NULL;
ALTER TABLE "gene" ALTER COLUMN "category" DROP NOT NULL;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250324152132638', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250324152132638', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
