BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "auth_api_token" ADD COLUMN "isGuest" boolean NOT NULL DEFAULT false;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "auth_session" ADD COLUMN "isGuest" boolean NOT NULL DEFAULT false;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "flumip_user" ADD COLUMN "termsAcceptedAt" timestamp without time zone;
ALTER TABLE "flumip_user" ADD COLUMN "termsVersion" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" ADD COLUMN "shareToken" text;
ALTER TABLE "project" ADD COLUMN "expires" timestamp without time zone;
ALTER TABLE "project" ADD COLUMN "queuedAt" timestamp without time zone;
CREATE UNIQUE INDEX "project_share_token_idx" ON "project" USING btree ("shareToken");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "project_grant" (
    "id" bigserial PRIMARY KEY,
    "projectId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "project_grant_pair_idx" ON "project_grant" USING btree ("projectId", "userId");
CREATE INDEX "project_grant_user_idx" ON "project_grant" USING btree ("userId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "publicMode" boolean NOT NULL DEFAULT false;
ALTER TABLE "settings" ADD COLUMN "maxProjectLifetimeDays" bigint NOT NULL DEFAULT 30;
ALTER TABLE "settings" ADD COLUMN "guestMaxProjects" bigint NOT NULL DEFAULT 10;
ALTER TABLE "settings" ADD COLUMN "termsVersion" bigint NOT NULL DEFAULT 1;
ALTER TABLE "settings" ADD COLUMN "publicNoticeText" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "imprintUrl" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "privacyUrl" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "maxConcurrentRuns" bigint NOT NULL DEFAULT 0;
ALTER TABLE "settings" ADD COLUMN "maxBwaThreads" bigint NOT NULL DEFAULT 0;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "project_grant"
    ADD CONSTRAINT "project_grant_fk_0"
    FOREIGN KEY("projectId")
    REFERENCES "project"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "project_grant"
    ADD CONSTRAINT "project_grant_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "flumip_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20261028111351759', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261028111351759', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
