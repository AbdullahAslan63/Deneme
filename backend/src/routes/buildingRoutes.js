import express from "express";
import {
  createBuilding,
  getBuildings,
  getBuildingById,
  updateBuilding,
  deleteBuilding,
} from "../controllers/buildingController.js";
import {
  getDuesByBuilding,
  updateDueStatus,
  updateBuildingDueAmount,
} from "../controllers/dueController.js";
import { getTicketsByBuilding } from "../controllers/ticketController.js";
import {
  getExpensesByBuilding,
  getExpenseSummary,
  createExpense,
} from "../controllers/expenseController.js";
import { postBuildingAnnouncement } from "../controllers/announcementController.js";

import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRoles } from "../middlewares/roleMiddleware.js";
import {
  validate,
  buildingSchemas,
  dueSchemas,
  ticketSchemas,
  expenseSchemas,
  notificationSchemas,
} from "../middlewares/validate.js";

const router = express.Router();

router.use(authMiddleware);
router.use(requireRoles("MANAGER"));

router.post("/", validate(buildingSchemas.create), createBuilding);
router.get("/", getBuildings);

// Aidatlar — /:id/... bina detayından önce (okunabilirlik; Express yine de doğru eşleştirir)
router.get("/:id/dues", validate(dueSchemas.getByBuilding), getDuesByBuilding);
router.get(
  "/:id/expenses/summary",
  validate(expenseSchemas.summaryByBuilding),
  getExpenseSummary
);
router.get("/:id/expenses", validate(expenseSchemas.listByBuilding), getExpensesByBuilding);
router.post("/:id/expenses", validate(expenseSchemas.create), createExpense);
router.get("/:id/tickets", validate(ticketSchemas.listByBuilding), getTicketsByBuilding);
router.post(
  "/:id/announcements",
  validate(notificationSchemas.announce),
  postBuildingAnnouncement
);
router.patch("/:id/due-amount", validate(dueSchemas.updateAmount), updateBuildingDueAmount);
router.patch("/:id/dues/:dueId/status", validate(dueSchemas.updateStatus), updateDueStatus);

router.get("/:id", validate(buildingSchemas.getById), getBuildingById);
router.put("/:id", validate(buildingSchemas.update), updateBuilding);
router.delete("/:id", validate(buildingSchemas.delete), deleteBuilding);

export default router;