import rateLimit from "express-rate-limit";

/**
 * Genel API rate limiter
 * Tüm endpoint'ler için 15 dakikada 100 istek
 */
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100, // IP başına 100 istek
  message: {
    success: false,
    message: "Çok fazla istek gönderdiniz. Lütfen 15 dakika sonra tekrar deneyin.",
  },
  standardHeaders: true, // `RateLimit-*` header'larını ekle
  legacyHeaders: false, // `X-RateLimit-*` header'larını devre dışı bırak
  // Skip successful requests (opsiyonel)
  // skip: (req, res) => res.statusCode < 400
});

/**
 * Auth endpoint'leri için daha agresif rate limiter
 * Brute-force saldırılarına karşı koruma
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 5, // IP başına 5 istek (login denemesi)
  message: {
    success: false,
    message: "Çok fazla giriş denemesi. Lütfen 15 dakika sonra tekrar deneyin.",
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Skip successful logins
  skipSuccessfulRequests: true,
});

/**
 * Şifre sıfırlama gibi hassas işlemler için
 */
export const strictLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 saat
  max: 3, // IP başına 3 istek
  message: {
    success: false,
    message: "Bu işlem için saatlik limit aşıldı. Lütfen daha sonra tekrar deneyin.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});
