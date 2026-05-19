import express from "express";
import { getMyDues } from "../controllers/dueController.js";
import { getMyTickets, createMyTicket } from "../controllers/ticketController.js";
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
import { validate, dueSchemas, meSchemas, ticketSchemas } from "../middlewares/validate.js";

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

/** GET /api/v1/me/tickets — yalnızca sakin */
router.get("/tickets", requireRoles("RESIDENT"), validate(ticketSchemas.myTickets), getMyTickets);

/** POST /api/v1/me/tickets — yalnızca sakin (daire JWT profilden) */
router.post(
  "/tickets",
  requireRoles("RESIDENT"),
  validate(ticketSchemas.createMyTicket),
  createMyTicket
);

export default router;
