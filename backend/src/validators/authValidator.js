import { z } from "zod";

/**
 * Kayıt olma validasyon şeması
 */
export const registerSchema = z.object({
  name: z
    .string()
    .min(2, "İsim en az 2 karakter olmalıdır.")
    .max(100, "İsim en fazla 100 karakter olabilir."),
  email: z
    .string()
    .email("Geçerli bir email adresi giriniz."),
  password: z
    .string()
    .min(8, "Şifre en az 8 karakter olmalıdır.")
    .max(100, "Şifre en fazla 100 karakter olabilir."),
  role: z
    .enum(["MANAGER", "RESIDENT"])
    .optional()
    .default("MANAGER"),
});

/**
 * Giriş yapma validasyon şeması
 */
export const loginSchema = z.object({
  email: z
    .string()
    .email("Geçerli bir email adresi giriniz."),
  password: z
    .string()
    .min(1, "Şifre gereklidir."),
});

/**
 * Telefon ile giriş validasyon şeması
 */
export const phoneLoginSchema = z.object({
  phone: z
    .string()
    .min(10, "Telefon numarası en az 10 karakter olmalıdır.")
    .max(15, "Telefon numarası en fazla 15 karakter olabilir."),
  password: z
    .string()
    .min(1, "Şifre gereklidir."),
});

/**
 * Token refresh validasyon şeması
 */
export const refreshTokenSchema = z.object({
  refreshToken: z
    .string()
    .min(1, "Refresh token gereklidir."),
});
