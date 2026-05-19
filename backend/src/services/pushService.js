import { prisma } from "../config/db.js";
import { getMessaging, isFirebaseReady } from "../config/firebase.js";
import { clearFcmToken } from "../services/fcmTokenService.js";

const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
  "messaging/invalid-argument",
]);

/**
 * FCM data payload — tüm değerler string olmalı.
 * @param {Record<string, unknown>} data
 */
function toFcmData(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [
      key,
      value === null || value === undefined ? "" : String(value),
    ])
  );
}

/**
 * Tek cihaza push gönderir.
 * @param {string} fcmToken
 * @param {{ title: string, body: string, data?: Record<string, unknown> }} payload
 */
export async function sendToToken(fcmToken, { title, body, data = {} }) {
  if (!isFirebaseReady()) {
    console.warn("[push] Firebase hazır değil — gönderim atlandı.");
    return { sent: false, skipped: true, reason: "firebase_not_ready" };
  }

  const messaging = getMessaging();
  if (!messaging) {
    return { sent: false, skipped: true, reason: "messaging_unavailable" };
  }

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: toFcmData(data),
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
    return { sent: true };
  } catch (err) {
    const code = err.code ?? err.errorInfo?.code;
    if (code && INVALID_TOKEN_CODES.has(code)) {
      await clearFcmToken(fcmToken);
      console.warn("[push] Geçersiz token temizlendi:", code);
    } else {
      console.warn("[push] Gönderim hatası:", code || err.message);
    }
    return { sent: false, error: err.message, code };
  }
}

/**
 * Kullanıcının kayıtlı FCM token'ına push gönderir.
 * @param {string} userId
 * @param {{ title: string, body: string, data?: Record<string, unknown> }} payload
 */
export async function sendToUser(userId, payload) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
    select: { fcmToken: true },
  });

  if (!user?.fcmToken) {
    return { sent: false, skipped: true, reason: "no_token" };
  }

  return sendToToken(user.fcmToken, payload);
}
