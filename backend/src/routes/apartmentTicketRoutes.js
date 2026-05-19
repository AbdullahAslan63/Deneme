import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRoles } from "../middlewares/roleMiddleware.js";
import { validate, ticketSchemas } from "../middlewares/validate.js";
import { createTicket } from "../controllers/ticketController.js";

const router = Router({ mergeParams: true });

router.use(authMiddleware);
router.use(requireRoles("RESIDENT"));

router.post("/", validate(ticketSchemas.create), createTicket);

export default router;
