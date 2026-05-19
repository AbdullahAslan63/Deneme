import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { validate } from "../middlewares/validate.js";
import { notificationSchemas } from "../validators/notificationValidator.js";
import {
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  createDevSeedNotification,
} from "../controllers/notificationController.js";

const router = Router();

router.use(authMiddleware);

/** Development / E2E test bildirimi oluştur */
const devSeedEnabled =
  process.env.NODE_ENV === "development" || process.env.AIDATPANEL_E2E === "1";

if (devSeedEnabled) {
  router.post("/dev/seed", createDevSeedNotification);
  /** test.py geriye dönük uyumluluk */
  router.post("/_e2e/seed", createDevSeedNotification);
}

router.get("/", validate(notificationSchemas.list), listNotifications);
router.patch("/read-all", markAllNotificationsRead);
router.patch(
  "/:id/read",
  validate(notificationSchemas.markRead),
  markNotificationRead
);

export default router;
