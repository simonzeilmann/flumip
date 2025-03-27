BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "settingsPassword" text NOT NULL DEFAULT 'changeme'::text;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250327192348239', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250327192348239', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
