import { prisma } from "../config/db.js";
import crypto from "crypto";

/**
 * Benzersiz davet kodu üret (collision durumunda retry)
 */
const generateUniqueCode = async (maxRetries = 3) => {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    // 8 hex → AP + 1 | 3 | 4 = AP3-B12-X7K9 (3+3+4; mobil / sözleşme ile uyumlu)
    const raw = crypto.randomBytes(4).toString("hex").toUpperCase();
    const formattedCode = `AP${raw.slice(0, 1)}-${raw.slice(1, 4)}-${raw.slice(4, 8)}`;

    // Kodun benzersiz olduğunu kontrol et
    const existing = await prisma.inviteCode.findUnique({
      where: { code: formattedCode }
    });

    if (!existing) {
      return formattedCode;
    }
  }

  throw new Error("Benzersiz davet kodu üretilemedi. Lütfen tekrar deneyin.");
};

// Davet kodu üret
const generateInviteCode = async (req, res, next) => {
  try {
    // POST /api/v1/apartments/:apartmentId/invite-code
    const { apartmentId } = req.params;
    const managerId = req.user.id;

    // Apartmanın bu yöneticiye ait olduğunu kontrol et
    const apartment = await prisma.apartment.findFirst({
      where: {
        id: apartmentId,
        building: { managerId }
      }
    });

    if (!apartment) {
      return res.status(403).json({
        success: false,
        message: "Bu daire için davet kodu üretme yetkiniz yok."
      });
    }

    // Benzersiz kod üret
    const formattedCode = await generateUniqueCode();

    // 7 gün geçerlilik süresi
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const inviteCode = await prisma.inviteCode.create({
      data: {
        code: formattedCode,
        apartmentId,
        expiresAt
      }
    });

    res.status(201).json({
      success: true,
      data: {
        id: inviteCode.id,
        apartmentId: inviteCode.apartmentId,
        code: inviteCode.code,
        expiresAt: inviteCode.expiresAt,
        usedAt: inviteCode.usedAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

export { generateInviteCode };
