BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "auth_session" ADD COLUMN "departments" json;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "flumip_user" ADD COLUMN "departments" json;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" DROP COLUMN "department";
ALTER TABLE "project" ADD COLUMN "department" text;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "oidcDepartmentClaim" text NOT NULL DEFAULT ''::text;

--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260924112557973', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924112557973', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
