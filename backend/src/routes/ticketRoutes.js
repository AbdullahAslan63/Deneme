import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRoles } from "../middlewares/roleMiddleware.js";
import { validate, ticketSchemas } from "../middlewares/validate.js";
import {
  getTicketById,
  addTicketUpdate,
  patchTicketStatus,
} from "../controllers/ticketController.js";

const router = Router();

router.use(authMiddleware);

router.get(
  "/:ticketId",
  validate(ticketSchemas.getById),
  getTicketById
);

router.post(
  "/:ticketId/updates",
  requireRoles("MANAGER"),
  validate(ticketSchemas.addUpdate),
  addTicketUpdate
);

router.patch(
  "/:ticketId/status",
  requireRoles("MANAGER"),
  validate(ticketSchemas.updateStatus),
  patchTicketStatus
);

export default router;
