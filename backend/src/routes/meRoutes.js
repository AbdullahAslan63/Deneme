import express from "express";
import { getMyDues } from "../controllers/dueController.js";
import {
  getMe,
  updateMe,
  deleteMe,
  updatePassword,
  updateLanguage,
  updateFcmToken,
} from "../controllers/meController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRoles } from "../middlewares/roleMiddleware.js";
import { validate, dueSchemas, meSchemas } from "../middlewares/validate.js";

const router = express.Router();

router.use(authMiddleware);

/** Profil / KVKK / FCM — MANAGER ve RESIDENT */
router.get("/", getMe);
router.put("/", validate(meSchemas.updateProfile), updateMe);
router.delete("/", deleteMe);
router.put("/password", validate(meSchemas.updatePassword), updatePassword);
router.put("/language", validate(meSchemas.updateLanguage), updateLanguage);
router.put("/fcm-token", validate(meSchemas.updateFcmToken), updateFcmToken);

/** GET /api/v1/me/dues — yalnızca sakin */
router.get("/dues", requireRoles("RESIDENT"), validate(dueSchemas.myDues), getMyDues);

export default router;
