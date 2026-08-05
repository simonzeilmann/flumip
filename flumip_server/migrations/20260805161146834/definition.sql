BEGIN;

--
-- Class AuthApiToken as table auth_api_token
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
-- Class AuthFlow as table auth_flow
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
-- Class AuthSession as table auth_session
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
-- Class FlumipUser as table flumip_user
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
-- Class Genome as table genome
--
CREATE TABLE "genome" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL DEFAULT ''::text,
    "path" text,
    "fastaPath" text,
    "refPath" text,
    "snpFolder" text,
    "category" text,
    "active" boolean NOT NULL DEFAULT true,
    "indexed" boolean NOT NULL DEFAULT false,
    "indexing" boolean NOT NULL DEFAULT false,
    "indexPID" bigint NOT NULL DEFAULT 0,
    "indexResults" bigint NOT NULL DEFAULT 0,
    "size" bigint NOT NULL DEFAULT 0
);

--
-- Class Project as table project
--
CREATE TABLE "project" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "folderName" text,
    "description" text NOT NULL DEFAULT ''::text,
    "genome" bigint,
    "snp" bigint,
    "tags" json,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "owner" bigint,
    "department" bigint,
    "trackToken" text,
    "genes" json,
    "bedFileCreated" boolean NOT NULL DEFAULT false,
    "active" boolean NOT NULL DEFAULT false,
    "pid" bigint,
    "size" bigint NOT NULL DEFAULT 0,
    "emailNotification" boolean NOT NULL DEFAULT false,
    "options" bigint NOT NULL,
    "started" timestamp without time zone,
    "completedIn" bigint,
    "error" text NOT NULL DEFAULT ''::text,
    "cleanup" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE INDEX "project_owner_idx" ON "project" USING btree ("owner");
CREATE UNIQUE INDEX "project_track_token_idx" ON "project" USING btree ("trackToken");

--
-- Class ProjectOptions as table project_options
--
CREATE TABLE "project_options" (
    "id" bigserial PRIMARY KEY,
    "minCaptureSize" bigint NOT NULL DEFAULT 162,
    "maxCaptureSize" bigint NOT NULL DEFAULT 162,
    "armLengths" text,
    "armLengthSums" text NOT NULL DEFAULT '40,41,42,43,44,45'::text,
    "extMinLength" bigint NOT NULL DEFAULT 16,
    "extMaxLength" bigint NOT NULL DEFAULT 18,
    "ligMinLength" bigint NOT NULL DEFAULT 18,
    "tagSizes" text NOT NULL DEFAULT '5,0'::text,
    "maskedArmThreshold" double precision NOT NULL DEFAULT 0.5,
    "targetArmCopy" bigint NOT NULL DEFAULT 20,
    "maxArmCopyProduct" bigint NOT NULL DEFAULT 75,
    "trf" boolean NOT NULL DEFAULT false,
    "genomeDir" text,
    "featureFlank" bigint NOT NULL DEFAULT 0,
    "captureIncrement" bigint NOT NULL DEFAULT 5,
    "logisticHeuristic" boolean NOT NULL DEFAULT false,
    "maxMipOverlap" bigint NOT NULL DEFAULT 30,
    "startingMipOverlap" bigint NOT NULL DEFAULT 0,
    "checkCopyNumber" boolean NOT NULL DEFAULT true,
    "sealBothStrands" boolean NOT NULL DEFAULT false,
    "halfSealBothStrands" boolean NOT NULL DEFAULT false,
    "doubleTileStrandUnaware" boolean NOT NULL DEFAULT false,
    "doubleTileStrandsSeparately" boolean NOT NULL DEFAULT false,
    "scoreMethod" text NOT NULL DEFAULT 'logistic'::text,
    "logisticOptimalScore" double precision NOT NULL DEFAULT 0.98,
    "svrOptimalScore" double precision NOT NULL DEFAULT 2.2,
    "logisticPriorityScore" double precision NOT NULL DEFAULT 0.9,
    "svrPriorityScore" double precision NOT NULL DEFAULT 1.5,
    "silentMode" boolean NOT NULL DEFAULT false,
    "bwaThreads" bigint NOT NULL DEFAULT 1
);

--
-- Class Settings as table settings
--
CREATE TABLE "settings" (
    "id" bigserial PRIMARY KEY,
    "demoMode" boolean NOT NULL DEFAULT false,
    "baseDir" text NOT NULL DEFAULT '/opt/flumip'::text,
    "projectDir" text NOT NULL DEFAULT '/opt/flumip/projects'::text,
    "genomeDir" text NOT NULL DEFAULT '/opt/flumip/data/genomes'::text,
    "customSnpDir" text NOT NULL DEFAULT '/opt/flumip/data/custom_snp'::text,
    "snpSourceAllowedHosts" text NOT NULL DEFAULT ''::text,
    "toolsDir" text NOT NULL DEFAULT '/opt/flumip/tools'::text,
    "mipgenExecutable" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/mipgen'::text,
    "exonExtractScript" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh'::text,
    "ucscTrackGenerator" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/tools/generate_ucsc_track.py'::text,
    "binCreationScript" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/tools/add_bins_to_refgene.py'::text,
    "bigGenePredToGenePredExecutable" text NOT NULL DEFAULT '/opt/flumip/tools/bigGenePredToGenePred'::text,
    "mailActive" boolean NOT NULL DEFAULT false,
    "smtpServer" text NOT NULL DEFAULT ''::text,
    "smtpPort" bigint NOT NULL DEFAULT 25,
    "smtpUser" text NOT NULL DEFAULT ''::text,
    "smtpPassword" text NOT NULL DEFAULT ''::text,
    "smtpFrom" text NOT NULL DEFAULT 'flumip@yourdomain.com'::text,
    "startTLS" boolean NOT NULL DEFAULT true,
    "loginRequired" boolean NOT NULL DEFAULT false,
    "settingsPassword" text NOT NULL DEFAULT 'changeme'::text,
    "oidcIssuer" text NOT NULL DEFAULT ''::text,
    "oidcClientId" text NOT NULL DEFAULT ''::text,
    "oidcClientSecret" text,
    "oidcScopes" text NOT NULL DEFAULT 'openid email profile'::text,
    "oidcButtonLabel" text NOT NULL DEFAULT 'Sign in with SSO'::text,
    "oidcAllowedEmailDomains" text NOT NULL DEFAULT ''::text,
    "oidcAdminEmails" text NOT NULL DEFAULT ''::text,
    "authPublicUrl" text NOT NULL DEFAULT ''::text
);

--
-- Class Snp as table snp
--
CREATE TABLE "snp" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL DEFAULT ''::text,
    "vcfPath" text NOT NULL,
    "tbiPath" text NOT NULL,
    "folder" text NOT NULL,
    "active" boolean NOT NULL,
    "private" boolean NOT NULL DEFAULT false,
    "size" bigint NOT NULL DEFAULT 0,
    "genome" bigint,
    "owner" bigint,
    "custom" boolean NOT NULL DEFAULT false,
    "status" text NOT NULL DEFAULT 'ready'::text,
    "statusMessage" text NOT NULL DEFAULT ''::text,
    "sourceVcfUrl" text,
    "sourceTbiUrl" text,
    "bytesDownloaded" bigint NOT NULL DEFAULT 0,
    "totalBytes" bigint NOT NULL DEFAULT 0,
    "statusUpdated" timestamp without time zone,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "snp_genome_idx" ON "snp" USING btree ("genome");
CREATE INDEX "snp_owner_idx" ON "snp" USING btree ("owner");
CREATE INDEX "snp_folder_idx" ON "snp" USING btree ("folder");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Foreign relations for "auth_api_token" table
--
ALTER TABLE ONLY "auth_api_token"
    ADD CONSTRAINT "auth_api_token_fk_0"
    FOREIGN KEY("authSessionId")
    REFERENCES "auth_session"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "auth_session" table
--
ALTER TABLE ONLY "auth_session"
    ADD CONSTRAINT "auth_session_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "flumip_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "project" table
--
ALTER TABLE ONLY "project"
    ADD CONSTRAINT "project_fk_0"
    FOREIGN KEY("snp")
    REFERENCES "snp"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "project"
    ADD CONSTRAINT "project_fk_1"
    FOREIGN KEY("owner")
    REFERENCES "flumip_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "snp" table
--
ALTER TABLE ONLY "snp"
    ADD CONSTRAINT "snp_fk_0"
    FOREIGN KEY("genome")
    REFERENCES "genome"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "snp"
    ADD CONSTRAINT "snp_fk_1"
    FOREIGN KEY("owner")
    REFERENCES "flumip_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


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
