import { prisma } from "../config/db.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { generateAccessToken, generateRefreshToken } from "../utils/generateTokens.js";

const register = async (req, res) => {
  const { name, email, password } = req.body;

  const mevcutKullanici = await prisma.user.findUnique({
    where: { email: email },
  });
  if (mevcutKullanici) {
    return res.status(400).json({ error: "Bu email adresi zaten kullanılıyor." });
  }
  const hashedPassword = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: {
      name,
      email,
      passwordHash: hashedPassword,
    },
  });
  res.status(201).json({ message: "Hesabınız başarıyla oluşturuldu.", user: user.id });
};

const login = async (req, res) => {
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({
    where: { email: email },
  });
  if (!user) {
    return res.status(400).json({ error: "Email veya şifre hatalı." });
  }
  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    return res.status(400).json({ error: "Email veya şifre hatalı." });
  }
  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);
  res.status(200).json({
    message: "Giriş başarılı.",
    accessToken,
    refreshToken,
    user: { id: user.id, email: user.email, name: user.name, role: user.role },
  });
};

const refreshToken = async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(401).json({ error: "Refresh token gerekli." });
  }
  try {
    const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);
    const user = await prisma.user.findUnique({ where: { id: decoded.id } });
    if (!user) {
      return res.status(404).json({ error: "Kullanıcı bulunamadı." });
    }
    const newAccessToken = generateAccessToken(user);
    res.status(200).json({ accessToken: newAccessToken });
  } catch (error) {
    res.status(403).json({ error: "Geçersiz refresh token." });
  }
};

const logout = async (req, res) => {
  // Client-side token silme islemi
  // Not: Stateless JWT'da server tarafinda token invalidation icin
  // blacklist/whitelist sistemi gerekir (Redis vb.)
  res.status(200).json({ message: "Cikis basarili." });
};

export { register, login, refreshToken, logout };
