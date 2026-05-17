import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRoles } from "../middlewares/roleMiddleware.js";
import { validate, expenseSchemas } from "../middlewares/validate.js";
import { updateExpense, deleteExpense } from "../controllers/expenseController.js";

const router = Router();

router.use(authMiddleware);
router.use(requireRoles("MANAGER"));

router.put("/:expenseId", validate(expenseSchemas.update), updateExpense);
router.delete("/:expenseId", validate(expenseSchemas.delete), deleteExpense);

export default router;
