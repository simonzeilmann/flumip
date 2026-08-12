BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "auth_api_token" (
    "id" bigserial PRIMARY KEY,
    "authSessionId" bigint NOT NULL,
    "tokenHash" text NOT NULL,
    "email" text NOT NULL,
    "isAdmin" boolean NOT NULL DEFAULT false,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "auth_api_token_hash_idx" ON "auth_api_token" USING btree ("tokenHash");
CREATE INDEX "auth_api_token_session_idx" ON "auth_api_token" USING btree ("authSessionId");
CREATE INDEX "auth_api_token_expires_idx" ON "auth_api_token" USING btree ("expires");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "auth_flow" (
    "id" bigserial PRIMARY KEY,
    "state" text NOT NULL,
    "codeVerifier" text NOT NULL,
    "nonce" text NOT NULL,
    "redirectUri" text NOT NULL,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "auth_flow_state_idx" ON "auth_flow" USING btree ("state");
CREATE INDEX "auth_flow_expires_idx" ON "auth_flow" USING btree ("expires");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "auth_session" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "cookieHash" text NOT NULL,
    "email" text NOT NULL,
    "isAdmin" boolean NOT NULL DEFAULT false,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires" timestamp without time zone NOT NULL,
    "lastSeen" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "auth_session_cookie_hash_idx" ON "auth_session" USING btree ("cookieHash");
CREATE INDEX "auth_session_expires_idx" ON "auth_session" USING btree ("expires");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "flumip_user" (
    "id" bigserial PRIMARY KEY,
    "email" text NOT NULL,
    "subject" text NOT NULL,
    "issuer" text NOT NULL,
    "displayName" text NOT NULL DEFAULT ''::text,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastLogin" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "flumip_user_identity_idx" ON "flumip_user" USING btree ("issuer", "subject");
CREATE INDEX "flumip_user_email_idx" ON "flumip_user" USING btree ("email");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "settings" ADD COLUMN "oidcIssuer" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "oidcClientId" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "oidcClientSecret" text;
ALTER TABLE "settings" ADD COLUMN "oidcScopes" text NOT NULL DEFAULT 'openid email profile'::text;
ALTER TABLE "settings" ADD COLUMN "oidcButtonLabel" text NOT NULL DEFAULT 'Sign in with SSO'::text;
ALTER TABLE "settings" ADD COLUMN "oidcAllowedEmailDomains" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "oidcAdminEmails" text NOT NULL DEFAULT ''::text;
ALTER TABLE "settings" ADD COLUMN "authPublicUrl" text NOT NULL DEFAULT ''::text;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "auth_api_token"
    ADD CONSTRAINT "auth_api_token_fk_0"
    FOREIGN KEY("authSessionId")
    REFERENCES "auth_session"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "auth_session"
    ADD CONSTRAINT "auth_session_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "flumip_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260730075011770', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260730075011770', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
