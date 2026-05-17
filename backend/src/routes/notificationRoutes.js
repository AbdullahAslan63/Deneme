import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { validate, notificationSchemas } from "../middlewares/validate.js";
import {
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
} from "../controllers/notificationController.js";
import { createForUsers } from "../services/notificationService.js";

const router = Router();

router.use(authMiddleware);

/** Yalnızca E2E: AIDATPANEL_E2E=1 iken createForUsers doğrulanır (üretimde kapalı). */
if (process.env.AIDATPANEL_E2E === "1") {
  router.post("/_e2e/seed", async (req, res, next) => {
    try {
      const data = await createForUsers([req.user.id], {
        type: "SYSTEM",
        title: "E2E test bildirimi",
        body: "Smoke test — bildirim kutusu",
        data: { route: "/manager-dashboard" },
      });
      res.status(201).json({ success: true, data });
    } catch (err) {
      next(err);
    }
  });
}

router.get("/", validate(notificationSchemas.list), listNotifications);
router.patch("/read-all", markAllNotificationsRead);
router.patch(
  "/:id/read",
  validate(notificationSchemas.markRead),
  markNotificationRead
);

export default router;
