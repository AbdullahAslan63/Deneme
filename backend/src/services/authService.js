import { prisma } from "../config/db.js";
import bcrypt from "bcryptjs";

/**
 * Kullanıcı oluşturma servisi
 */
export const createUserService = async (userData) => {
  const { name, email, password, role = "MANAGER", apartmentId = null } = userData;

  const hashedPassword = await bcrypt.hash(password, 10);

  return await prisma.user.create({
    data: {
      name,
      email,
      passwordHash: hashedPassword,
      role,
      apartmentId,
    },
  });
};

/**
 * Email kontrolü servisi
 */
export const findUserByEmail = async (email) => {
  return await prisma.user.findUnique({
    where: { email },
  });
};

/**
 * Şifre doğrulama servisi
 */
export const validatePassword = async (plainPassword, hashedPassword) => {
  return await bcrypt.compare(plainPassword, hashedPassword);
};
