import {
  getProfileService,
  updateProfileService,
  changePasswordService,
  updateLanguageService,
  updateFcmTokenService,
  softDeleteAccountService,
} from "../services/meService.js";
import { HttpError } from "../utils/httpError.js";

const handleHttp = (err, res, next) => {
  if (err instanceof HttpError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
  }
  next(err);
};

export const getMe = async (req, res, next) => {
  try {
    const data = await getProfileService(req.user.id);
    res.status(200).json({ success: true, data });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const updateMe = async (req, res, next) => {
  try {
    const data = await updateProfileService(req.user.id, req.body);
    res.status(200).json({
      success: true,
      message: "Profil güncellendi.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const updatePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    await changePasswordService(req.user.id, currentPassword, newPassword);
    res.status(200).json({
      success: true,
      message: "Şifre güncellendi. Diğer cihazlarda tekrar giriş yapmanız gerekebilir.",
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const updateLanguage = async (req, res, next) => {
  try {
    const data = await updateLanguageService(req.user.id, req.body.language);
    res.status(200).json({
      success: true,
      message: "Dil güncellendi.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const updateFcmToken = async (req, res, next) => {
  try {
    await updateFcmTokenService(req.user.id, req.body.fcmToken);
    res.status(200).json({ success: true, message: "FCM token kaydedildi." });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const deleteMe = async (req, res, next) => {
  try {
    await softDeleteAccountService(req.user.id);
    res.status(200).json({
      success: true,
      message: "Hesabınız kapatıldı ve kişisel veriler maskelendi.",
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};
