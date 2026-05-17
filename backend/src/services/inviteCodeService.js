import { prisma } from "../config/db.js";

/**
 * Davet kodunu DB ile eşleştirmek için normalize et (trim, büyük harf, iç boşlukları kaldır).
 */
export const normalizeInviteCode = (code) =>
  typeof code === "string" ? code.trim().toUpperCase().replace(/\s+/g, "") : "";

/**
 * Davet kodunu doğrular. Hata durumunda anlamlı mesajlı `Error` fırlatır.
 */
export const validateInviteCode = async (code) => {  const normalized = normalizeInviteCode(code);
  const inviteCode = await prisma.inviteCode.findUnique({
    where: { code: normalized },
    include: { apartment: { include: { building: true } } },
  });

  if (!inviteCode) {
    throw new Error("Geçersiz davet kodu.");
  }

  if (inviteCode.usedAt) {
    throw new Error("Bu davet kodu zaten kullanılmış.");
  }

  if (inviteCode.expiresAt < new Date()) {
    throw new Error("Davet kodunun süresi dolmuş.");
  }

  return inviteCode;
};
