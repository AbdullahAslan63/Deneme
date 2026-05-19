import { config } from "dotenv";
config();

import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaNeon } from "@prisma/adapter-neon";
import pg from "pg";

const connectionString = process.env.DATABASE_URL?.trim();
if (!connectionString) {
  console.error(
    "DATABASE_URL tanımlı değil — backend/.env içinde bağlantı dizesini ayarlayın."
  );
  process.exit(1);
}

const useNeon =
  /neon\.tech/i.test(connectionString) ||
  process.env.PRISMA_DATABASE_ADAPTER === "neon";

// Development'da sadece connection status göster - güvenlik açığı düzeltildi
if (process.env.NODE_ENV === "development") {
  console.log(
    `Database connection status: Checking... (${useNeon ? "Neon" : "PostgreSQL"})`
  );
}

const adapter = useNeon
  ? new PrismaNeon({ connectionString })
  : new PrismaPg(new pg.Pool({ connectionString }));

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
