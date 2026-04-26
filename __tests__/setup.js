// Jest test ortamı için setup
// Testler çalışmadan önce çalışır

import { prisma } from "../src/config/db.js";

// Tüm testlerden önce veritabanını temizle
beforeAll(async () => {
  // Test veritabanı kullanılıyorsa tabloları temizle
  if (process.env.NODE_ENV === "test") {
    // Sırayla bağımlı tabloları temizle (ilişki sırasına göre)
    await prisma.notification.deleteMany();
    await prisma.ticketUpdate.deleteMany();
    await prisma.ticket.deleteMany();
    await prisma.due.deleteMany();
    await prisma.inviteCode.deleteMany();
    await prisma.expense.deleteMany();
    await prisma.user.deleteMany();
    await prisma.apartment.deleteMany();
    await prisma.building.deleteMany();
    await prisma.subscription.deleteMany();
  }
});

// Her testten sonra cleanup
afterEach(async () => {
  // Gerekirse test verilerini temizle
});

// Tüm testler bittikten sonra bağlantıyı kapat
afterAll(async () => {
  await prisma.$disconnect();
});
