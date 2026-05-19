import {
  listForUser,
  markRead,
  markAllRead,
} from "../services/notificationService.js";
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
      message: "Bildirim okundu olarak işaretlendi.",
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
      message: "Tüm bildirimler okundu olarak işaretlendi.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};
