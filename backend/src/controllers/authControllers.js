import { prisma } from "../config/db.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { generateAccessToken, generateRefreshToken } from "../utils/generateTokens.js";
import { validateInviteCode } from "../services/inviteCodeService.js";
import {
  requestPasswordResetService,
  resetPasswordWithTokenService,
} from "../services/passwordResetService.js";
import { HttpError } from "../utils/httpError.js";

const register = async (req, res, next) => {
  try {
    const { name, email, phone, password } = req.body;

    const mevcutKullanici = await prisma.user.findFirst({
      where: { email, deletedAt: null },
    });
    if (mevcutKullanici) {
      return res.status(409).json({ success: false, message: "Bu email adresi zaten kullanılıyor." });
    }

    if (phone) {
      const mevcutTelefon = await prisma.user.findFirst({
        where: { phone, deletedAt: null },
      });
      if (mevcutTelefon) {
        return res.status(409).json({ success: false, message: "Bu telefon numarası zaten kullanılıyor." });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: {
        name,
        email,
        phone,
        passwordHash: hashedPassword,
        role: "MANAGER", // Normal kayıt olanlar otomatik MANAGER
      },
    });
    res.status(201).json({
      success: true,
      message: "Hesabınız başarıyla oluşturuldu.",
      data: {
        user: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        language: user.language,
        apartmentId: user.apartmentId,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { identifier, password } = req.body;

    // identifier '@' içeriyorsa email, yoksa telefon numarası
    const isEmail = identifier.includes('@');

    const user = isEmail
      ? await prisma.user.findFirst({
          where: { email: identifier, deletedAt: null },
        })
      : await prisma.user.findFirst({
          where: { phone: identifier, deletedAt: null },
        });

    if (!user || user.deletedAt) {
      return res.status(401).json({
        success: false,
        message: "Email/telefon veya şifre hatalı."
      });
    }
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: "Email/telefon veya şifre hatalı."
      });
    }
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);
    res.status(200).json({
      success: true,
      message: "Giriş başarılı.",
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          phone: user.phone,
          language: user.language,
          apartmentId: user.apartmentId,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        },
      }
    });
  } catch (error) {
    next(error);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: "Refresh token gerekli."
      });
    }
    const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);
    const tokenRv = decoded.rv ?? 0;
    const user = await prisma.user.findFirst({
      where: { id: decoded.id, deletedAt: null },
    });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Kullanıcı bulunamadı."
      });
    }
    if ((user.refreshTokenVersion ?? 0) !== tokenRv) {
      return res.status(401).json({
        success: false,
        message: "Oturum sonlandırıldı. Lütfen tekrar giriş yapın.",
      });
    }
    const newAccessToken = generateAccessToken(user);
    res.status(200).json({
      success: true,
      data: { accessToken: newAccessToken }
    });
  } catch (error) {
    next(error);
  }
};

const join = async (req, res, next) => {
  try {
    const { name, email, phone, password, inviteCode } = req.body;

    // Davet kodunu doğrula
    const inviteCodeData = await validateInviteCode(inviteCode);

    const mevcutKullanici = await prisma.user.findFirst({
      where: { email, deletedAt: null },
    });
    if (mevcutKullanici) {
      return res.status(409).json({
        success: false,
        message: "Bu email adresi zaten kullanılıyor."
      });
    }

    if (phone) {
      const mevcutTelefon = await prisma.user.findFirst({
        where: { phone, deletedAt: null },
      });
      if (mevcutTelefon) {
        return res.status(409).json({
          success: false,
          message: "Bu telefon numarası zaten kullanılıyor."
        });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // Transaction: kullanıcı oluştur + davet kodunu kullanıldı işaretle
    const result = await prisma.$transaction(async (tx) => {
      // RESIDENT olarak kullanıcı oluştur
      const user = await tx.user.create({
        data: {
          name,
          email,
          phone,
          passwordHash: hashedPassword,
          role: "RESIDENT",
          apartmentId: inviteCodeData.apartmentId
        },
      });

      // Davet kodunu kullanıldı olarak işaretle
      await tx.inviteCode.update({
        where: { id: inviteCodeData.id },
        data: {
          usedAt: new Date(),
          usedBy: user.id,
        },
      });

      return user;
    });

    // Token'lar oluştur
    const accessToken = generateAccessToken(result);
    const refreshToken = generateRefreshToken(result);

    res.status(201).json({
      success: true,
      message: "Apartmana başarıyla katıldınız.",
      data: {
        accessToken,
        refreshToken,
        user: {
          id: result.id,
          email: result.email,
          name: result.name,
          phone: result.phone,
          role: result.role,
          language: result.language,
          apartmentId: result.apartmentId,
          createdAt: result.createdAt,
          updatedAt: result.updatedAt,
        },
      }
    });
  } catch (error) {
    if (error.message.includes("davet kodu")) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    await prisma.user.update({
      where: { id: req.user.id },
      data: { refreshTokenVersion: { increment: 1 } },
    });
    res.status(200).json({
      success: true,
      message: "Çıkış başarılı.",
    });
  } catch (error) {
    next(error);
  }
};

const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    await requestPasswordResetService(email);
    res.status(200).json({
      success: true,
      message:
        "E-posta adresi sistemde kayıtlıysa şifre sıfırlama talimatları gönderildi.",
    });
  } catch (error) {
    next(error);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const { token, password } = req.body;
    await resetPasswordWithTokenService(token, password);
    res.status(200).json({
      success: true,
      message: "Şifreniz güncellendi. Yeni şifreyle giriş yapabilirsiniz.",
    });
  } catch (error) {
    if (error instanceof HttpError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

export { register, login, refreshToken, join, logout, forgotPassword, resetPassword };