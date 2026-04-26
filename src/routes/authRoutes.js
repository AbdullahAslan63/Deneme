import express from "express";
import { register, login, refreshToken, logout } from "../controllers/authControllers.js";
import { authLimiter } from "../middlewares/rateLimitMiddleware.js";
import { validate, authSchemas } from "../middlewares/validate.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

// Rate limiting - Brute force koruması (başarısız girişleri sayar)
router.use(authLimiter);

// Auth endpoint'leri
router.post("/register", validate(authSchemas.register), register);
router.post("/login", validate(authSchemas.login), login);
router.post("/refresh", validate(authSchemas.refreshToken), refreshToken);
router.post("/logout", authMiddleware, logout);

export default router;
