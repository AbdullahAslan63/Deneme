import express from "express";
import {
  register,
  login,
  refreshToken,
  join,
  logout,
  forgotPassword,
  resetPassword,
} from "../controllers/authControllers.js";
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
router.post("/join", validate(authSchemas.join), join);
router.post("/forgot-password", validate(authSchemas.forgotPassword), forgotPassword);
router.post("/reset-password", validate(authSchemas.resetPassword), resetPassword);
router.post("/logout", authMiddleware, logout);

export default router;
