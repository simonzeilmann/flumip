BEGIN;

--
-- ACTION ALTER TABLE
--
--
-- HAND-ADDED, NOT GENERATED. Keep this if you ever recreate this migration, and
-- keep it BEFORE the drop below.
--
-- `genome.snp` was a denormalised list of SNP ids, and until `snp.genome` existed
-- it was the only record of which genome an SNP belonged to. Dropping the column
-- without converting first would strand every SNP that predates `snp.genome` —
-- `getAllSnpForGenome` queries that column, so every SNP picker on the install
-- would come up empty and it would look exactly like data loss.
--
-- This ran in Dart until now (`SnpService.backfillGenomeLinks`), which was fine
-- while the column still existed but cannot work once it is gone: application
-- code runs *after* migrations. Doing it here makes the conversion atomic with
-- the schema change and independent of which version an install upgrades from.
--
-- Touches nothing on an install that already ran the Dart backfill.
UPDATE "snp" AS s
   SET "genome" = g."id"
  FROM "genome" AS g
 WHERE s."genome" IS NULL
   AND g."snp" IS NOT NULL
   AND (g."snp")::jsonb @> to_jsonb(s."id");

ALTER TABLE "genome" DROP COLUMN "snp";

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260805161146834', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260805161146834', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
