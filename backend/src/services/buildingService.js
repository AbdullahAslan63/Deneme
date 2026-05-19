import { prisma } from "../config/db.js";
import { endOfDueDayIstanbul, getIstanbulYearMonth } from "../utils/trDueDate.js";

/**
 * Bina oluştur (transaction: Building + Apartments + Dues)
 * Daireler: 1A, 1B, 2A, 2B... şeklinde isimlendirilir
 * Aidatlar: Bulunulan aydan yıl sonuna kadar tüm daireler için oluşturulur
 */
export const createBuildingService = async ({
  name,
  address,
  city,
  totalFloors,
  apartmentsPerFloor,
  dueAmount,
  dueDay = 1,
  currency = "TRY",
  managerId,
}) => {
  return await prisma.$transaction(
    async (tx) => {
      // 1. Building oluştur
      const building = await tx.building.create({
        data: {
          name,
          address,
          city,
          totalFloors,
          apartmentsPerFloor,
          dueAmount,
          dueDay,
          currency,
          managerId,
        },
      });

      // 2. Apartments — sıralı INSERT (Promise.all deadlock riskini azaltır)
      const apartments = [];
      const totalFloorsNum = totalFloors || 1;
      const apartmentsPerFloorNum = apartmentsPerFloor || 2;

      for (let floor = 1; floor <= totalFloorsNum; floor++) {
        for (let unit = 0; unit < apartmentsPerFloorNum; unit++) {
          const letter = String.fromCharCode(65 + unit); // A, B, C...
          const number = `${floor}${letter}`;
          const apartment = await tx.apartment.create({
            data: {
              number,
              floor,
              buildingId: building.id,
            },
          });
          apartments.push(apartment);
        }
      }

      // 3. Dues (bulunulan aydan yıl sonuna kadar) — sıralı INSERT
      if (dueAmount) {
        const { year: currentYear, month: currentMonth } = getIstanbulYearMonth();

        for (const apartment of apartments) {
          for (let month = currentMonth; month <= 12; month++) {
            const dueDate = endOfDueDayIstanbul(currentYear, month, dueDay);
            await tx.due.create({
              data: {
                apartmentId: apartment.id,
                amount: dueAmount,
                currency,
                month,
                year: currentYear,
                dueDate,
                status: "PENDING",
              },
            });
          }
        }
      }

      return await tx.building.findUnique({
        where: { id: building.id },
        include: {
          apartments: {
            orderBy: { number: "asc" },
          },
        },
      });
    },
    {
      maxWait: 10_000,
      timeout: 60_000,
    }
  );
};

export const getBuildingsService = async (managerId) => {
  return await prisma.building.findMany({
    where: { managerId },
    orderBy: { createdAt: "desc" },
    include: {
      _count: {
        select: { apartments: true },
      },
    },
  });
};

export const getBuildingByIdService = async (id, managerId) => {
  return await prisma.building.findFirst({
    where: { id, managerId },
  });
};

export const updateBuildingService = async (id, managerId, data) => {
  const building = await prisma.building.findFirst({
    where: { id, managerId },
  });

  if (!building) return null;

  return await prisma.building.update({
    where: { id },
    data,
  });
};

export const deleteBuildingService = async (id, managerId) => {
  const building = await prisma.building.findFirst({
    where: { id, managerId },
  });

  if (!building) return null;

  return await prisma.building.delete({
    where: { id },
  });
};