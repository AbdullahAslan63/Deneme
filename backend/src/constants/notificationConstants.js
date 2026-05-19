/** Bildirim listesi sayfalama sınırları */
export const NOTIFICATION_DEFAULT_LIMIT = 20;
export const NOTIFICATION_MAX_LIMIT = 50;
export const NOTIFICATION_MIN_LIMIT = 1;

/** FCM token validasyon sınırları (AIDATPANEL.md) */
export const FCM_TOKEN_MIN_LENGTH = 10;
export const FCM_TOKEN_MAX_LENGTH = 4096;

/** Prisma NotificationType — API sözleşmesi */
export const NOTIFICATION_TYPES = Object.freeze({
  DUE_REMINDER: "DUE_REMINDER",
  DUE_PAID: "DUE_PAID",
  TICKET_CREATED: "TICKET_CREATED",
  TICKET_UPDATE: "TICKET_UPDATE",
  ANNOUNCEMENT: "ANNOUNCEMENT",
  SYSTEM: "SYSTEM",
  DEKONT_RECEIVED: "DEKONT_RECEIVED",
});

/** Kullanıcıya dönen mesajlar */
export const NOTIFICATION_MESSAGES = Object.freeze({
  MARK_READ: "Bildirim okundu olarak işaretlendi.",
  MARK_ALL_READ: "Tüm bildirimler okundu olarak işaretlendi.",
  NOT_FOUND: "Bildirim bulunamadı.",
  INVALID_CURSOR: "Geçersiz sayfalama imleci (cursor).",
  FCM_SAVED: "FCM token kaydedildi.",
  DEV_SEED_OK: "Test bildirimi oluşturuldu.",
});

/** Development / E2E test bildirimi */
export const DEV_SEED_NOTIFICATION = Object.freeze({
  type: NOTIFICATION_TYPES.SYSTEM,
  title: "AidatPanel test bildirimi",
  body: "Bildirim modülü çalışıyor — Postman veya mobil uygulama ile doğrulayabilirsiniz.",
  data: { route: "/manager-dashboard" },
});
