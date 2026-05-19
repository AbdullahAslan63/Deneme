import { prisma } from "../config/db.js";
import { HttpError } from "../utils/httpError.js";

/**
 * Kullanıcının FCM push token'ını kaydeder.
 * PUT /api/v1/me/fcm-token
 * @param {string} userId
 * @param {string} fcmToken
 */
export async function saveFcmToken(userId, fcmToken) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
    select: { id: true },
  });

  if (!user) {
    throw new HttpError(401, "Kullanıcı bulunamadı.");
  }

  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
}

/**
 * Geçersiz token temizliği (pushService tarafından da kullanılır).
 * @param {string} fcmToken
 */
export async function clearFcmToken(fcmToken) {
  await prisma.user.updateMany({
    where: { fcmToken },
    data: { fcmToken: null },
  });
}
