import jwt from "jsonwebtoken";

const generateAccessToken = (user) => {
  return jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: "15m",
  });
};

const generateRefreshToken = (user) => {
  const rv = user.refreshTokenVersion ?? 0;
  return jwt.sign(
    { id: user.id, role: user.role, rv },
    process.env.REFRESH_TOKEN_SECRET,
    {
      expiresIn: "30d",
    }
  );
};

export { generateAccessToken, generateRefreshToken };
