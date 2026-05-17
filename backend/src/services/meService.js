import bcrypt from "bcryptjs";
import { prisma } from "../config/db.js";
import { HttpError } from "../utils/httpError.js";

/** API yanıtlarında kullanıcı için güvenli alanlar (`passwordHash`, `refreshTokenVersion` yok). */
export const userPublicSelect = {
  id: true,
  email: true,
  name: true,
  role: true,
  phone: true,
  language: true,
  apartmentId: true,
  createdAt: true,
  updatedAt: true,
};

export function toPublicUser(user) {
  if (!user) return null;
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    role: user.role,
    phone: user.phone,
    language: user.language,
    apartmentId: user.apartmentId,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

export async function getProfileService(userId) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
    select: userPublicSelect,
  });
  if (!user) {
    throw new HttpError(401, "Kullanıcı bulunamadı.");
  }
  return toPublicUser(user);
}

export async function updateProfileService(userId, { name, phone, language }) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
  });
  if (!user) {
    throw new HttpError(401, "Kullanıcı bulunamadı.");
  }

  if (phone !== undefined && phone !== null && phone !== user.phone) {
    const taken = await prisma.user.findFirst({
      where: { phone, NOT: { id: userId }, deletedAt: null },
      select: { id: true },
    });
    if (taken) {
      throw new HttpError(409, "Bu telefon numarası zaten kullanılıyor.");
    }
  }

  const data = {};
  if (name !== undefined) data.name = name;
  if (phone !== undefined) data.phone = phone;
  if (language !== undefined) data.language = language;

  const updated = await prisma.user.update({
    where: { id: userId },
    data,
    select: userPublicSelect,
  });
  return toPublicUser(updated);
}

export async function changePasswordService(userId, currentPassword, newPassword) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
  });
  if (!user) {
    throw new HttpError(401, "Kullanıcı bulunamadı.");
  }
  const ok = await bcrypt.compare(currentPassword, user.passwordHash);
  if (!ok) {
    throw new HttpError(400, "Mevcut şifre hatalı.");
  }
  const passwordHash = await bcrypt.hash(newPassword, 10);
  await prisma.user.update({
    where: { id: userId },
    data: {
      passwordHash,
      refreshTokenVersion: { increment: 1 },
    },
  });
}

export async function updateLanguageService(userId, language) {
  const ok = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
    select: { id: true },
  });
  if (!ok) {
    throw new HttpError(401, "Kullanıcı bulunamadı.");
  }
  const updated = await prisma.user.update({
    where: { id: userId },
    data: { language },
    select: userPublicSelect,
  });
  return toPublicUser(updated);
}

export async function updateFcmTokenService(userId, fcmToken) {
  const ok = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
    select: { id: true },
  });
  if (!ok) {
    throw new HttpError(401, "Kullanıcı bulunamadı.");
  }
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
}

/**
 * KVKK: kayıt silinmez; PII maskelenir, oturumlar iptal edilir.
 * Yöneticinin en az bir yönettiği bina varsa 409.
 */
export async function softDeleteAccountService(userId) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
    include: {
      _count: { select: { managedBuildings: true } },
    },
  });
  if (!user) {
    throw new HttpError(401, "Kullanıcı bulunamadı.");
  }
  if (user._count.managedBuildings > 0) {
    throw new HttpError(
      409,
      "Yönettiğiniz bina kayıtları varken hesap kapatılamaz. Önce binaları silin veya başka yöneticiye devredin."
    );
  }

  const ghostEmail = `deleted.${user.id}@closed.aidatpanel.invalid`;
  const random = await bcrypt.hash(`${user.id}:${Date.now()}`, 4);

  await prisma.$transaction([
    prisma.passwordResetToken.deleteMany({ where: { userId } }),
    prisma.user.update({
      where: { id: userId },
      data: {
        deletedAt: new Date(),
        email: ghostEmail,
        phone: null,
        name: "Silinmiş kullanıcı",
        passwordHash: random,
        apartmentId: null,
        fcmToken: null,
        refreshTokenVersion: { increment: 1 },
      },
    }),
  ]);
}
