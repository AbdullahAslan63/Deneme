import { prisma } from "../config/db.js";
import { userPublicSelect } from "./meService.js";

/**
 * Binadaki tüm aidatları listele (yönetici için)
 * Filtreleme: month, year, status
 */
export const getDuesByBuildingService = async (buildingId, managerId, filters = {}) => {
  // Önce binanın yöneticiye ait olduğunu kontrol et
  const building = await prisma.building.findFirst({
    where: { id: buildingId, managerId },
  });

  if (!building) return null;

  const { month, year, status } = filters;

  // Filtre koşulları
  const whereClause = {
    apartment: { buildingId },
  };

  if (month) whereClause.month = parseInt(String(month), 10);
  if (year) whereClause.year = parseInt(String(year), 10);
  if (status) whereClause.status = status;

  const dues = await prisma.due.findMany({
    where: whereClause,
    include: {
      apartment: {
        select: {
          id: true,
          number: true,
          floor: true,
          resident: { select: userPublicSelect },
        },
      },
    },
    orderBy: [{ year: "desc" }, { month: "desc" }, { apartment: { number: "asc" } }],
  });

  return dues.map((due) => {
    const { apartment, ...rest } = due;
    return {
      ...rest,
      apartmentNumber: apartment.number,
      apartment: {
        id: apartment.id,
        number: apartment.number,
        floor: apartment.floor,
      },
      resident: apartment.resident ?? null,
    };
  });
};

/**
 * Aidat durumunu güncelle (yönetici için)
 */
export const updateDueStatusService = async (dueId, managerId, { status, paidAt, note, buildingId }) => {
  // Due'nun yöneticinin binasına ait olduğunu kontrol et
  const due = await prisma.due.findUnique({
    where: { id: dueId },
    include: {
      apartment: {
        include: { building: true },
      },
    },
  });

  if (!due) return null;

  if (due.apartment.building.managerId !== managerId) {
    return { forbidden: true };
  }

  if (buildingId && due.apartment.buildingId !== buildingId) {
    return { forbidden: true };
  }

  // Güncelleme verisi
  const updateData = { status };

  if (status === "PAID") {
    updateData.paidAt = paidAt ? new Date(paidAt) : new Date();
    updateData.overdueDays = 0;
  } else if (status === "WAIVED") {
    updateData.paidAt = null;
    updateData.overdueDays = 0;
  } else if (status === "OVERDUE") {
    // Gecikme gün sayısını hesapla
    const today = new Date();
    const dueDate = new Date(due.dueDate);
    const diffTime = today.getTime() - dueDate.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    updateData.overdueDays = Math.max(0, diffDays);
  }

  if (note !== undefined) {
    updateData.note = note;
  }

  const updated = await prisma.due.update({
    where: { id: dueId },
    data: updateData,
    include: {
      apartment: {
        select: { id: true, number: true },
      },
    },
  });

  return {
    ...updated,
    apartmentNumber: updated.apartment?.number ?? null,
  };
};

/**
 * Sakinin kendi aidatlarını listele
 */
export const getMyDuesService = async (userId, filters = {}) => {
  // Kullanıcının apartmanını bul
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: { apartment: true },
  });

  if (!user || !user.apartment) {
    return [];
  }

  const { status, year, month } = filters;

  const whereClause = {
    apartmentId: user.apartment.id,
  };

  if (status) whereClause.status = status;
  if (year) whereClause.year = parseInt(String(year), 10);
  if (month) whereClause.month = parseInt(String(month), 10);

  const dues = await prisma.due.findMany({
    where: whereClause,
    orderBy: [{ year: "desc" }, { month: "desc" }],
  });

  // Building bilgisini ekle
  const building = await prisma.building.findUnique({
    where: { id: user.apartment.buildingId },
    select: { id: true, name: true, address: true },
  });

  return dues.map((due) => ({
    ...due,
    apartmentId: user.apartment.id,
    apartmentNumber: user.apartment.number,
    apartment: {
      id: user.apartment.id,
      number: user.apartment.number,
    },
    building,
  }));
};

/**
 * Bina aidat bedelini güncelle
 * affectCurrent: true ise mevcut PENDING aidatları da güncelle
 */
export const updateBuildingDueAmountService = async (buildingId, managerId, { dueAmount, dueDay, currency, affectCurrent = false }) => {
  // Binanın yöneticiye ait olduğunu kontrol et
  const building = await prisma.building.findFirst({
    where: { id: buildingId, managerId },
  });

  if (!building) return null;

  return await prisma.$transaction(async (tx) => {
    // Building'i güncelle
    const updated = await tx.building.update({
      where: { id: buildingId },
      data: {
        dueAmount,
        ...(dueDay && { dueDay }),
        ...(currency && { currency }),
      },
    });

    // Mevcut PENDING aidatları da güncelle (isteğe bağlı)
    if (affectCurrent && dueAmount) {
      await tx.due.updateMany({
        where: {
          apartment: { buildingId },
          status: "PENDING",
        },
        data: {
          amount: dueAmount,
          ...(currency && { currency }),
        },
      });
    }

    return updated;
  });
};
