-- CreateEnum
CREATE TYPE "DekontStatus" AS ENUM (
    'RECEIVED',
    'EXTRACTING',
    'EXTRACT_FAILED',
    'PARSED',
    'PARSE_LOW_CONFIDENCE',
    'MATCHING',
    'MATCHED',
    'MATCH_AMBIGUOUS',
    'UNMATCHED',
    'PAYMENT_APPLIED',
    'PAYMENT_PARTIAL',
    'REJECTED',
    'RECIPIENT_MISMATCH',
    'NEEDS_MANAGER_REVIEW'
);

-- CreateEnum
CREATE TYPE "DekontSource" AS ENUM ('RESIDENT_UPLOAD', 'MANAGER_UPLOAD');

-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'DEKONT_RECEIVED';
ALTER TYPE "NotificationType" ADD VALUE 'DEKONT_MATCHED';
ALTER TYPE "NotificationType" ADD VALUE 'DEKONT_PAYMENT_APPLIED';
ALTER TYPE "NotificationType" ADD VALUE 'DEKONT_NEEDS_REVIEW';

-- AlterTable
ALTER TABLE "Building" ADD COLUMN     "collectionIban" TEXT,
ADD COLUMN     "collectionAccountTitle" TEXT,
ADD COLUMN     "paymentReferenceTemplate" TEXT,
ADD COLUMN     "collectionVerifiedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "Dekont" (
    "id" TEXT NOT NULL,
    "buildingId" TEXT NOT NULL,
    "apartmentId" TEXT,
    "uploadedById" TEXT NOT NULL,
    "dueId" TEXT,
    "status" "DekontStatus" NOT NULL DEFAULT 'RECEIVED',
    "source" "DekontSource" NOT NULL,
    "storedPath" TEXT NOT NULL,
    "originalFilename" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "rawText" TEXT,
    "parsedJson" JSONB,
    "parserProfile" TEXT,
    "parseError" TEXT,
    "recipientVerified" BOOLEAN,
    "verificationJson" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Dekont_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DuePayment" (
    "id" TEXT NOT NULL,
    "dueId" TEXT NOT NULL,
    "dekontId" TEXT,
    "amount" DECIMAL(12,2) NOT NULL,
    "paidAt" TIMESTAMP(3) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'TRY',
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DuePayment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Dekont_buildingId_createdAt_idx" ON "Dekont"("buildingId", "createdAt");

-- CreateIndex
CREATE INDEX "Dekont_uploadedById_idx" ON "Dekont"("uploadedById");

-- CreateIndex
CREATE INDEX "Dekont_status_idx" ON "Dekont"("status");

-- CreateIndex
CREATE INDEX "Dekont_apartmentId_idx" ON "Dekont"("apartmentId");

-- CreateIndex
CREATE INDEX "DuePayment_dueId_idx" ON "DuePayment"("dueId");

-- CreateIndex
CREATE INDEX "DuePayment_dekontId_idx" ON "DuePayment"("dekontId");

-- AddForeignKey
ALTER TABLE "Dekont" ADD CONSTRAINT "Dekont_buildingId_fkey" FOREIGN KEY ("buildingId") REFERENCES "Building"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dekont" ADD CONSTRAINT "Dekont_apartmentId_fkey" FOREIGN KEY ("apartmentId") REFERENCES "Apartment"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dekont" ADD CONSTRAINT "Dekont_uploadedById_fkey" FOREIGN KEY ("uploadedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dekont" ADD CONSTRAINT "Dekont_dueId_fkey" FOREIGN KEY ("dueId") REFERENCES "Due"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DuePayment" ADD CONSTRAINT "DuePayment_dueId_fkey" FOREIGN KEY ("dueId") REFERENCES "Due"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DuePayment" ADD CONSTRAINT "DuePayment_dekontId_fkey" FOREIGN KEY ("dekontId") REFERENCES "Dekont"("id") ON DELETE SET NULL ON UPDATE CASCADE;
