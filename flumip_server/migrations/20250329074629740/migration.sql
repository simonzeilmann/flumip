BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "genome" ADD COLUMN "size" bigint NOT NULL DEFAULT 0;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "snp" ADD COLUMN "size" bigint NOT NULL DEFAULT 0;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250329074629740', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250329074629740', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
