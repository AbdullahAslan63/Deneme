import {
  listForUser,
  markRead,
  markAllRead,
  seedDevNotification,
} from "../services/notificationService.js";
import {
  NOTIFICATION_MESSAGES,
  DEV_SEED_NOTIFICATION,
} from "../constants/notificationConstants.js";
import { HttpError } from "../utils/httpError.js";

const handleHttp = (err, res, next) => {
  if (err instanceof HttpError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
  }
  next(err);
};

/**
 * GET /api/v1/notifications
 * Query: unreadOnly, limit (1-50), cursor (uuid)
 */
export const listNotifications = async (req, res, next) => {
  try {
    const { unreadOnly, limit, cursor } = req.query;
    const data = await listForUser(req.user.id, {
      unreadOnly,
      limit,
      cursor,
    });
    res.status(200).json({ success: true, data });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

/**
 * PATCH /api/v1/notifications/:id/read
 */
export const markNotificationRead = async (req, res, next) => {
  try {
    const data = await markRead(req.user.id, req.params.id);
    res.status(200).json({
      success: true,
      message: NOTIFICATION_MESSAGES.MARK_READ,
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

/**
 * PATCH /api/v1/notifications/read-all
 */
export const markAllNotificationsRead = async (req, res, next) => {
  try {
    const data = await markAllRead(req.user.id);
    res.status(200).json({
      success: true,
      message: NOTIFICATION_MESSAGES.MARK_ALL_READ,
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

/**
 * POST /api/v1/notifications/dev/seed
 * Yalnızca development veya AIDATPANEL_E2E=1
 */
export const createDevSeedNotification = async (req, res, next) => {
  try {
    const data = await seedDevNotification(req.user.id, DEV_SEED_NOTIFICATION);
    res.status(201).json({
      success: true,
      message: NOTIFICATION_MESSAGES.DEV_SEED_OK,
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};
