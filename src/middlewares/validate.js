import { z } from "zod";

/**
 * Zod schema validation middleware'i oluşturur
 * @param {z.ZodSchema} schema - Zod schema objesi
 * @returns {Function} Express middleware
 * 
 * Kullanım:
 * router.post("/register", validate(registerSchema), register);
 */
export const validate = (schema) => {
  return (req, res, next) => {
    try {
      // Body'yi validate et
      if (schema.body) {
        req.body = schema.body.parse(req.body);
      }

      // Query parametrelerini validate et
      if (schema.query) {
        req.query = schema.query.parse(req.query);
      }

      // URL parametrelerini validate et
      if (schema.params) {
        req.params = schema.params.parse(req.params);
      }

      next();
    } catch (error) {
      next(error);
    }
  };
};

/**
 * Auth endpoint'leri için validation schemaları
 */
export const authSchemas = {
  register: {
    body: z.object({
      name: z
        .string()
        .min(2, "İsim en az 2 karakter olmalıdır")
        .max(50, "İsim en fazla 50 karakter olabilir"),
      email: z
        .string()
        .email("Geçerli bir email adresi giriniz"),
      password: z
        .string()
        .min(6, "Şifre en az 6 karakter olmalıdır")
        .max(100, "Şifre en fazla 100 karakter olabilir"),
    }),
  },

  login: {
    body: z.object({
      email: z
        .string()
        .email("Geçerli bir email adresi giriniz"),
      password: z
        .string()
        .min(1, "Şifre gereklidir"),
    }),
  },

  refreshToken: {
    body: z.object({
      refreshToken: z
        .string()
        .min(1, "Refresh token gereklidir"),
    }),
  },
};

/**
 * Building endpoint'leri için validation schemaları
 * Yusuf'un kullanması için hazır
 */
export const buildingSchemas = {
  create: {
    body: z.object({
      name: z
        .string()
        .min(2, "Bina adı en az 2 karakter olmalıdır")
        .max(100, "Bina adı en fazla 100 karakter olabilir"),
      address: z
        .string()
        .min(5, "Adres en az 5 karakter olmalıdır")
        .max(200, "Adres en fazla 200 karakter olabilir"),
      city: z
        .string()
        .min(2, "Şehir en az 2 karakter olmalıdır")
        .max(50, "Şehir en fazla 50 karakter olabilir"),
    }),
  },

  update: {
    params: z.object({
      id: z.string().uuid("Geçerli bir ID giriniz"),
    }),
    body: z.object({
      name: z
        .string()
        .min(2, "Bina adı en az 2 karakter olmalıdır")
        .max(100, "Bina adı en fazla 100 karakter olabilir")
        .optional(),
      address: z
        .string()
        .min(5, "Adres en az 5 karakter olmalıdır")
        .max(200, "Adres en fazla 200 karakter olabilir")
        .optional(),
      city: z
        .string()
        .min(2, "Şehir en az 2 karakter olmalıdır")
        .max(50, "Şehir en fazla 50 karakter olabilir")
        .optional(),
    }),
  },

  getById: {
    params: z.object({
      id: z.string().uuid("Geçerli bir ID giriniz"),
    }),
  },

  delete: {
    params: z.object({
      id: z.string().uuid("Geçerli bir ID giriniz"),
    }),
  },
};

/**
 * Apartment endpoint'leri için validation schemaları
 */
export const apartmentSchemas = {
  create: {
    params: z.object({
      buildingId: z.string().uuid("Geçerli bir bina ID'si giriniz"),
    }),
    body: z.object({
      number: z
        .string()
        .min(1, "Daire numarası gereklidir")
        .max(10, "Daire numarası en fazla 10 karakter olabilir"),
      floor: z
        .number()
        .int("Kat tam sayı olmalıdır")
        .min(-5, "Kat -5'ten küçük olamaz")
        .max(200, "Kat 200'den büyük olamaz")
        .optional(),
    }),
  },

  getByBuilding: {
    params: z.object({
      buildingId: z.string().uuid("Geçerli bir bina ID'si giriniz"),
    }),
  },

  delete: {
    params: z.object({
      buildingId: z.string().uuid("Geçerli bir bina ID'si giriniz"),
      id: z.string().uuid("Geçerli bir daire ID'si giriniz"),
    }),
  },
};
