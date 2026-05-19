import { prisma } from "../config/db.js";
import { assertManagerOwnsBuilding } from "../utils/access.js";
import { NOTIFICATION_TYPES } from "../constants/notificationConstants.js";
import { createForUsers } from "./notificationService.js";

/**
 * Binadaki aktif sakinlere duyuru (in-app + FCM).
 * @param {string} buildingId
 * @param {string} managerId
 * @param {{ title: string, body: string }} payload
 */
export async function sendBuildingAnnouncementService(
  buildingId,
  managerId,
  { title, body }
) {
  await assertManagerOwnsBuilding(buildingId, managerId);

  const residents = await prisma.user.findMany({
    where: {
      deletedAt: null,
      role: "RESIDENT",
      apartmentId: { not: null },
      apartment: { buildingId },
    },
    select: { id: true },
  });

  const userIds = residents.map((r) => r.id);

  if (userIds.length === 0) {
    return { created: 0, pushSent: 0, pushFailed: 0 };
  }

  const result = await createForUsers(userIds, {
    type: NOTIFICATION_TYPES.ANNOUNCEMENT,
    title,
    body,
    data: {
      buildingId,
      route: "/resident-dashboard",
    },
  });

  return {
    created: result.dbCount,
    pushSent: result.pushSent,
    pushFailed: result.pushFailed,
    pushSkipped: result.pushSkipped,
  };
}
