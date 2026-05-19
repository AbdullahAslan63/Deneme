import { z } from "zod";
import {
  NOTIFICATION_DEFAULT_LIMIT,
  NOTIFICATION_MAX_LIMIT,
  NOTIFICATION_MIN_LIMIT,
  FCM_TOKEN_MIN_LENGTH,
  FCM_TOKEN_MAX_LENGTH,
} from "../constants/notificationConstants.js";

/** GET /api/v1/notifications query */
export const listNotificationsQuerySchema = z.object({
  unreadOnly: z
    .string()
    .optional()
    .transform((v) => {
      if (v === "true") return true;
      if (v === "false") return false;
      return undefined;
    }),
  limit: z
    .string()
    .optional()
    .transform((v) => (v ? parseInt(v, 10) : NOTIFICATION_DEFAULT_LIMIT))
    .pipe(z.number().int().min(NOTIFICATION_MIN_LIMIT).max(NOTIFICATION_MAX_LIMIT)),
  cursor: z.string().uuid("Geçersiz cursor").optional(),
});

/** PATCH /api/v1/notifications/:id/read params */
export const markNotificationReadParamsSchema = z.object({
  id: z.string().uuid("Geçerli bir bildirim ID'si giriniz"),
});

/** POST /api/v1/buildings/:id/announcements */
export const buildingAnnouncementSchema = {
  params: z.object({
    id: z.string().uuid("Geçerli bir bina ID'si giriniz"),
  }),
  body: z.object({
    title: z.string().min(1).max(120),
    body: z.string().min(1).max(2000),
  }),
};

/** PUT /api/v1/me/fcm-token */
export const updateFcmTokenBodySchema = z.object({
  fcmToken: z
    .string()
    .min(FCM_TOKEN_MIN_LENGTH, "FCM token çok kısa")
    .max(FCM_TOKEN_MAX_LENGTH, "FCM token çok uzun"),
});

/** validate.js middleware ile uyumlu export */
export const notificationSchemas = {
  list: { query: listNotificationsQuerySchema },
  markRead: { params: markNotificationReadParamsSchema },
  announce: buildingAnnouncementSchema,
};

export const fcmSchemas = {
  updateToken: { body: updateFcmTokenBodySchema },
};
