import { prisma } from "../config/db.js";
import { HttpError } from "./httpError.js";

/**
 * Yöneticinin binaya erişimi var mı? Yoksa 404 (enumeration önleme).
 * @returns {Promise<import("@prisma/client").Building>}
 */
export async function assertManagerOwnsBuilding(buildingId, managerId) {
  const building = await prisma.building.findFirst({
    where: { id: buildingId, managerId },
  });
  if (!building) {
    throw new HttpError(404, "Bina bulunamadı veya erişim yetkiniz yok.");
  }
  return building;
}

/**
 * Sakinin daireye bağlı olduğunu doğrular.
 * @returns {Promise<import("@prisma/client").Apartment>}
 */
export async function assertResidentOwnsApartment(apartmentId, userId) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null, role: "RESIDENT" },
    select: { apartmentId: true },
  });
  if (!user?.apartmentId || user.apartmentId !== apartmentId) {
    throw new HttpError(403, "Bu daire için işlem yapma yetkiniz yok.");
  }
  const apartment = await prisma.apartment.findUnique({
    where: { id: apartmentId },
  });
  if (!apartment) {
    throw new HttpError(404, "Daire bulunamadı.");
  }
  return apartment;
}

/**
 * Talep detayı: yönetici (bina sahibi) veya talep sahibi sakin.
 * @returns {Promise<import("@prisma/client").Ticket & { apartment: { buildingId: string, building: { managerId: string } } }>}
 */
export async function assertCanAccessTicket(ticketId, user) {
  const ticket = await prisma.ticket.findUnique({
    where: { id: ticketId },
    include: {
      apartment: {
        select: {
          buildingId: true,
          building: { select: { managerId: true } },
        },
      },
    },
  });

  if (!ticket) {
    throw new HttpError(404, "Talep bulunamadı.");
  }

  const isOwner = ticket.userId === user.id;
  const isManager =
    user.role === "MANAGER" &&
    ticket.apartment.building.managerId === user.id;

  if (!isOwner && !isManager) {
    throw new HttpError(404, "Talep bulunamadı.");
  }

  return ticket;
}

/**
 * Gider kaydı — yönetici bina sahibi mi?
 * @returns {Promise<import("@prisma/client").Expense & { building: { managerId: string } }>}
 */
export async function assertManagerOwnsExpense(expenseId, managerId) {
  const expense = await prisma.expense.findUnique({
    where: { id: expenseId },
    include: { building: { select: { managerId: true } } },
  });
  if (!expense || expense.building.managerId !== managerId) {
    throw new HttpError(404, "Gider kaydı bulunamadı.");
  }
  return expense;
}
