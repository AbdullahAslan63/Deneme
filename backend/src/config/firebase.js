import admin from "firebase-admin";

let initialized = false;

export function isFirebaseReady() {
  return initialized;
}

/**
 * Firebase Admin SDK — production'da FIREBASE_SERVICE_ACCOUNT_JSON zorunlu.
 * @returns {boolean} push kullanılabilir mi
 */
export function initFirebase() {
  const isProduction = process.env.NODE_ENV === "production";
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();

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
