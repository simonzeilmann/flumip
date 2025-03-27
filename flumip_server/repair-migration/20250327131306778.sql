BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "genome" DROP COLUMN "indexResults";
ALTER TABLE "genome" ADD COLUMN "indexResults" bigint NOT NULL DEFAULT 0;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "toolsDir" text NOT NULL DEFAULT '/opt/flumip/tools'::text;
ALTER TABLE "settings" ADD COLUMN "mailActive" boolean NOT NULL DEFAULT false;
ALTER TABLE "settings" ADD COLUMN "smtpServer" text NOT NULL DEFAULT 'localhost'::text;
ALTER TABLE "settings" ADD COLUMN "smtpPort" bigint NOT NULL DEFAULT 25;
ALTER TABLE "settings" ADD COLUMN "smtpUser" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "smtpPassword" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "smtpFrom" text NOT NULL DEFAULT 'flumip@localhost'::text;
ALTER TABLE "settings" ADD COLUMN "startTLS" boolean NOT NULL DEFAULT true;
ALTER TABLE "settings" ADD COLUMN "loginRequired" boolean NOT NULL DEFAULT false;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20250327084157458', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250327084157458', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();

--
-- MIGRATION VERSION FOR _repair
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('_repair', '20250327131306778', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250327131306778', "timestamp" = now();


COMMIT;
