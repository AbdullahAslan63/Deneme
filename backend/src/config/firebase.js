import admin from "firebase-admin";
import { existsSync, readFileSync } from "node:fs";
import { isAbsolute, resolve } from "node:path";

let initialized = false;

function resolveCredentialPath(candidate) {
  const trimmed = candidate.trim();
  return isAbsolute(trimmed) ? trimmed : resolve(process.cwd(), trimmed);
}

/** JSON string veya service account dosya yolu. */
function readCredentialFile(path) {
  const resolved = resolveCredentialPath(path);
  if (!existsSync(resolved)) {
    throw new Error(
      `Service account dosyası bulunamadı: ${resolved} (FIREBASE_SERVICE_ACCOUNT_JSON veya FIREBASE_SERVICE_ACCOUNT_PATH)`
    );
  }
  return readFileSync(resolved, "utf8");
}

function loadServiceAccountJson() {
  const fromEnv = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (fromEnv) {
    // Tek satır JSON (production önerisi)
    if (fromEnv.startsWith("{")) {
      return fromEnv;
    }
    // Sık yapılan hata: env'ye dosya adı/yolu yazılmış — dosyadan oku
    return readCredentialFile(fromEnv);
  }

  const path = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
  if (path) {
    if (process.env.NODE_ENV === "production" && !path.startsWith("/")) {
      console.warn(
        "[firebase] Production'da FIREBASE_SERVICE_ACCOUNT_PATH yerine FIREBASE_SERVICE_ACCOUNT_JSON (tek satır JSON) önerilir."
      );
    }
    return readCredentialFile(path);
  }

  return null;
}

export function isFirebaseReady() {
  return initialized;
}

/**
 * Firebase Admin SDK — production'da FIREBASE_SERVICE_ACCOUNT_JSON zorunlu.
 * @returns {boolean} push kullanılabilir mi
 */
export function initFirebase() {
  const isProduction = process.env.NODE_ENV === "production";
  const raw = loadServiceAccountJson();

  if (!raw) {
    if (isProduction) {
      console.error(
        "[firebase] FIREBASE_SERVICE_ACCOUNT_JSON production ortamında zorunludur."
      );
      process.exit(1);
    }
    console.warn(
      "[firebase] FIREBASE_SERVICE_ACCOUNT_JSON tanımlı değil — push devre dışı (development)."
    );
    return false;
  }

  try {
    const serviceAccount = JSON.parse(raw);
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    initialized = true;
    console.log("[firebase] Admin SDK başlatıldı.");
    return true;
  } catch (err) {
    console.error("[firebase] Başlatma hatası:", err.message);
    if (isProduction) {
      process.exit(1);
    }
    return false;
  }
}

/** @returns {import("firebase-admin/messaging").Messaging | null} */
export function getMessaging() {
  if (!initialized) {
    return null;
  }
  return admin.messaging();
}
