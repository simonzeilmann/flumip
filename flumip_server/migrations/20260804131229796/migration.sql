BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" DROP CONSTRAINT IF EXISTS "project_fk_0";
--
-- ACTION ALTER TABLE
--
ALTER TABLE "snp" ADD COLUMN "genome" bigint;
ALTER TABLE "snp" ADD COLUMN "owner" bigint;
ALTER TABLE "snp" ADD COLUMN "custom" boolean NOT NULL DEFAULT false;
ALTER TABLE "snp" ADD COLUMN "status" text NOT NULL DEFAULT 'ready'::text;
ALTER TABLE "snp" ADD COLUMN "statusMessage" text NOT NULL DEFAULT ''::text;
ALTER TABLE "snp" ADD COLUMN "sourceVcfUrl" text;
ALTER TABLE "snp" ADD COLUMN "sourceTbiUrl" text;
ALTER TABLE "snp" ADD COLUMN "bytesDownloaded" bigint NOT NULL DEFAULT 0;
ALTER TABLE "snp" ADD COLUMN "totalBytes" bigint NOT NULL DEFAULT 0;
ALTER TABLE "snp" ADD COLUMN "statusUpdated" timestamp without time zone;
ALTER TABLE "snp" ADD COLUMN "created" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
CREATE INDEX "snp_genome_idx" ON "snp" USING btree ("genome");
CREATE INDEX "snp_owner_idx" ON "snp" USING btree ("owner");
CREATE INDEX "snp_folder_idx" ON "snp" USING btree ("folder");
--
-- HAND-ADDED, NOT GENERATED. Keep this if you ever recreate this migration.
--
-- Pre-flight for the new project.snp foreign key below. Nothing has ever deleted
-- an Snp row, so on a healthy install this touches zero rows — but a genome
-- directory that was dropped and re-scanned, or a hand-edited database, can leave
-- a project pointing at an id that is gone, and ADD CONSTRAINT would then abort
-- the whole migration on an install we cannot inspect.
--
UPDATE "project" SET "snp" = NULL
 WHERE "snp" IS NOT NULL
   AND "snp" NOT IN (SELECT "id" FROM "snp");
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "project"
    ADD CONSTRAINT "project_fk_1"
    FOREIGN KEY("owner")
    REFERENCES "flumip_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "project"
    ADD CONSTRAINT "project_fk_0"
    FOREIGN KEY("snp")
    REFERENCES "snp"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
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
-- MIGRATION VERSION FOR flumip
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('flumip', '20260804131229796', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260804131229796', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
