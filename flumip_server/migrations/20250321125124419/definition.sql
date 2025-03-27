BEGIN;

--
-- Class Gene as table gene
--
CREATE TABLE "gene" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL DEFAULT ''::text,
    "path" text NOT NULL,
    "fastaPath" text NOT NULL,
    "refPath" text NOT NULL,
    "snpFolder" text NOT NULL,
    "snp" json,
    "category" text NOT NULL,
    "active" boolean NOT NULL DEFAULT true,
    "indexed" boolean NOT NULL DEFAULT false,
    "indexing" boolean NOT NULL DEFAULT false,
    "indexPID" bigint NOT NULL DEFAULT 0,
    "indexResults" text NOT NULL DEFAULT ''::text
);

--
-- Class Project as table project
--
CREATE TABLE "project" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "folderName" text,
    "description" text NOT NULL DEFAULT ''::text,
    "gene" bigint,
    "snp" bigint,
    "tags" json,
    "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "owner" bigint,
    "department" bigint,
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

--
-- Class ProjectOptions as table project_options
--
CREATE TABLE "project_options" (
    "id" bigserial PRIMARY KEY,
    "fasta" bigint,
    "snp" bigint,
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
    "baseDir" text NOT NULL DEFAULT '/opt/flumip'::text,
    "projectDir" text NOT NULL DEFAULT '/opt/flumip/projects'::text,
    "geneDir" text NOT NULL DEFAULT '/opt/flumip/genes'::text,
    "mipgenExecutable" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/mipgen'::text,
    "exonExtractScript" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh'::text,
    "ucscTrackGenerator" text NOT NULL DEFAULT '/opt/flumip/MIPGEN/tools/generate_ucsc_track.py'::text
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
    "private" boolean NOT NULL DEFAULT false
);

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
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

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
    VALUES ('flumip', '20250321125124419', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250321125124419', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
