import { Router } from "express";
import { generateInviteCode } from "../controllers/inviteCodeController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRoles } from "../middlewares/roleMiddleware.js";
import { validate, apartmentSchemas } from "../middlewares/validate.js";

// Üst rota /apartments/:apartmentId/invite-code — :apartmentId alt router'a düşsün
const router = Router({ mergeParams: true });

router.use(authMiddleware);
router.use(requireRoles("MANAGER"));

// Davet kodu üret (sadece yönetici)
// UUID validasyonu eklendi - apartmentId parametresi kontrol edilir
router.post("/", validate(apartmentSchemas.generateInviteCode), generateInviteCode);

export default router;
