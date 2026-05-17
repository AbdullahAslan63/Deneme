import { config } from "dotenv";
config();

import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import pg from "pg";

// Development'da sadece connection status göster - güvenlik açığı düzeltildi
if (process.env.NODE_ENV === "development") {
  console.log("Database connection status: Checking...");
}

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
});

const adapter = new PrismaPg(pool);

const prisma = new PrismaClient({
  log:
    process.env.NODE_ENV === "development"
      ? ["query", "error", "warn"]
      : ["error"],
  adapter,
});

const connectDB = async () => {
  try {
    await prisma.$connect();
    console.log("DB Connected via Prisma");
  } catch (error) {
    console.log("Database connection error:", error);
    process.exit(1);
  }
};

const disconnectDB = async () => {
  await prisma.$disconnect();
};

export { prisma, connectDB, disconnectDB };
