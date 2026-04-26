/**
 * Global Error Handler Middleware
 * Tüm hataları merkezi olarak yönetir
 */

export const errorHandler = (err, req, res, next) => {
  console.error("Error:", err);

  // Zod validation hatası
  if (err.name === "ZodError") {
    return res.status(400).json({
      success: false,
      message: "Validasyon hatası",
      errors: err.errors.map((e) => ({
        field: e.path.join("."),
        message: e.message,
      })),
    });
  }

  // Prisma hataları
  if (err.code) {
    // Prisma unique constraint hatası
    if (err.code === "P2002") {
      return res.status(400).json({
        success: false,
        message: "Bu kayıt zaten mevcut",
        error: `Unique constraint failed on: ${err.meta?.target}`,
      });
    }

    // Prisma foreign key hatası
    if (err.code === "P2003") {
      return res.status(400).json({
        success: false,
        message: "İlişkili kayıt bulunamadı",
        error: "Foreign key constraint failed",
      });
    }

    // Prisma kayıt bulunamadı
    if (err.code === "P2025") {
      return res.status(404).json({
        success: false,
        message: "Kayıt bulunamadı",
        error: err.meta?.cause || "Record not found",
      });
    }
  }

  // JWT hataları
  if (err.name === "JsonWebTokenError") {
    return res.status(401).json({
      success: false,
      message: "Geçersiz token",
      error: err.message,
    });
  }

  if (err.name === "TokenExpiredError") {
    return res.status(401).json({
      success: false,
      message: "Token süresi dolmuş",
      error: err.message,
    });
  }

  // Rate limit hatası
  if (err.status === 429) {
    return res.status(429).json({
      success: false,
      message: "Çok fazla istek gönderdiniz",
      error: "Rate limit exceeded",
    });
  }

  // Varsayılan hata (500)
  const statusCode = err.statusCode || err.status || 500;
  const message = err.message || "Sunucu hatası";

  res.status(statusCode).json({
    success: false,
    message: process.env.NODE_ENV === "production" 
      ? "Bir hata oluştu" 
      : message,
    ...(process.env.NODE_ENV !== "production" && { stack: err.stack }),
  });
};

/**
 * 404 Not Found Handler
 * Tanımlanmamış route'lar için
 */
export const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route bulunamadı: ${req.method} ${req.originalUrl}`,
  });
};
