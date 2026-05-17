/**
 * JWT (authMiddleware) sonrası kullanıcı rolünü doğrular.
 * Prisma UserRole: MANAGER | RESIDENT
 */

export const requireRoles = (...allowedRoles) => {
  return (req, res, next) => {
    const role = req.user?.role;
    if (!role) {
      return res.status(401).json({
        success: false,
        message: "Kimlik doğrulama gerekli.",
      });
    }
    if (!allowedRoles.includes(role)) {
      return res.status(403).json({
        success: false,
        message: "Bu işlem için yetkiniz yok.",
      });
    }
    next();
  };
};
