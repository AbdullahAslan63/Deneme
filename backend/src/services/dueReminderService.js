import { NOTIFICATION_TYPES } from "../constants/notificationConstants.js";
import { DUE_REMINDER_RESIDENT } from "../constants/notificationTemplates.js";
import { prisma } from "../config/db.js";
import { assertManagerOwnsBuilding } from "../utils/access.js";
import { createForUsers } from "./notificationService.js";

/**
 * Binadaki PENDING/OVERDUE aidatlar için sakinlere hatırlatma (in-app + FCM).
 * POST /api/v1/buildings/:buildingId/dues/remind
 */
export async function remindBuildingDuesService(
  buildingId,
  managerId,
  { month, year, dueIds }
) {
  const building = await assertManagerOwnsBuilding(buildingId, managerId);

  const where = {
    apartment: { buildingId },
    status: { in: ["PENDING", "OVERDUE"] },
  };

  if (month != null && year != null) {
    where.month = parseInt(String(month), 10);
    where.year = parseInt(String(year), 10);
  }

  if (dueIds?.length) {
    where.id = { in: dueIds };
  }

  const dues = await prisma.due.findMany({
    where,
    include: {
      apartment: {
        select: {
          id: true,
          number: true,
          resident: { select: { id: true } },
        },
      },
    },
  });

  if (dues.length === 0) {
    return { reminded: 0, pushSent: 0, pushFailed: 0, pushSkipped: 0 };
  }

  const notifiedUserIds = new Set();
  let pushSent = 0;
  let pushFailed = 0;
  let pushSkipped = 0;

  for (const due of dues) {
    const residentId = due.apartment?.resident?.id;
    if (!residentId || notifiedUserIds.has(residentId)) {
      continue;
    }
    notifiedUserIds.add(residentId);

    const amount =
      due.amount != null ? Number(due.amount).toFixed(2) : "0.00";
    const currency = due.currency ?? building.currency ?? "TRY";

    const result = await createForUsers([residentId], {
      type: NOTIFICATION_TYPES.DUE_REMINDER,
      title: DUE_REMINDER_RESIDENT.title,
      body: DUE_REMINDER_RESIDENT.body(due.month, due.year, amount, currency),
      data: {
        dueId: due.id,
        buildingId,
        apartmentId: due.apartmentId,
        month: String(due.month),
        year: String(due.year),
        route: "/resident-dashboard",
      },
    });

    pushSent += result.pushSent;
    pushFailed += result.pushFailed;
    pushSkipped += result.pushSkipped;
  }

  return {
    reminded: notifiedUserIds.size,
    pushSent,
    pushFailed,
    pushSkipped,
  };
}
