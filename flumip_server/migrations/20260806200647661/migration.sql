BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "demoModeRetentionHours" bigint NOT NULL DEFAULT 168;

--
-- ACTION RENAME SCHEDULED FUTURE CALLS (hand-added)
--
-- DemoModeCleanup moved off Serverpod's deprecated identifier-based API onto
-- the generated scheduler, which registers it under a different name. Rows
-- scheduled by the old code still say 'demoModeCleanup' and would fire against
-- a handler that no longer exists, so every project created before this upgrade
-- would silently lose its demo-mode cleanup.
UPDATE "serverpod_future_call"
   SET "name" = 'DemoModeCleanupRunFutureCall'
 WHERE "name" = 'demoModeCleanup';

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260806200647661', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260806200647661', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
