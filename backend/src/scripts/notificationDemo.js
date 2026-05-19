/**
 * AidatPanel — Bildirim modülü uçtan uca demo script.
 *
 * Kullanım (API ayaktayken):
 *   cd backend
 *   npm run demo:notifications
 *
 * Gereksinim: Docker Postgres + npm run dev
 */
import { config } from "dotenv";
config();

const BASE = (process.env.AIDATPANEL_API_BASE || "http://127.0.0.1:4200/api/v1").replace(/\/$/, "");
const PASSWORD = "DemoNotif123";

const log = (step, msg) => console.log(`[${step}] ${msg}`);
const ok = (msg) => console.log(`  ✓ ${msg}`);
const fail = (msg) => {
  console.error(`  ✗ ${msg}`);
  process.exit(1);
};

async function api(method, path, { token, body } = {}) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  let json;
  try {
    json = await res.json();
  } catch {
    json = { success: false, message: await res.text() };
  }

  return { status: res.status, json };
}

async function main() {
  const suffix = Date.now();
  const email = `demo.notif.${suffix}@test.local`;
  const phone = `+9055${String(suffix).slice(-8)}`;

  log("1/8", "Yönetici kaydı");
  let r = await api("POST", "/auth/register", {
    body: { name: "Demo Yönetici", email, password: PASSWORD, phone },
  });
  if (r.status !== 201) fail(`Register: ${r.status} ${JSON.stringify(r.json)}`);
  ok("Kayıt tamam");

  log("2/8", "Giriş + JWT");
  r = await api("POST", "/auth/login", {
    body: { identifier: email, password: PASSWORD },
  });
  if (r.status !== 200 || !r.json.data?.accessToken) {
    fail(`Login: ${r.status} ${JSON.stringify(r.json)}`);
  }
  const token = r.json.data.accessToken;
  ok("Token alındı");

  log("3/8", "PUT /me/fcm-token");
  r = await api("PUT", "/me/fcm-token", {
    token,
    body: { fcmToken: "f".repeat(140) },
  });
  if (r.status !== 200) fail(`FCM: ${r.status} ${JSON.stringify(r.json)}`);
  ok(r.json.message);

  log("4/8", "GET /notifications (boş kutu)");
  r = await api("GET", "/notifications", { token });
  if (r.status !== 200) fail(`List: ${r.status}`);
  ok(`unreadCount=${r.json.data.unreadCount}`);

  log("5/8", "POST /notifications/dev/seed");
  r = await api("POST", "/notifications/dev/seed", { token });
  if (r.status === 404) {
    fail("dev/seed 404 — NODE_ENV=development veya AIDATPANEL_E2E=1 gerekli");
  }
  if (r.status !== 201) fail(`Seed: ${r.status} ${JSON.stringify(r.json)}`);
  const notifId = r.json.data?.notifications?.[0]?.id;
  if (!notifId) fail("Seed bildirim id yok");
  ok(`Bildirim oluşturuldu: ${notifId}`);

  log("6/8", "GET /notifications?unreadOnly=true");
  r = await api("GET", "/notifications?unreadOnly=true&limit=10", { token });
  if (r.status !== 200 || r.json.data.unreadCount < 1) {
    fail(`Unread list: ${JSON.stringify(r.json)}`);
  }
  ok(`Okunmamış: ${r.json.data.unreadCount}`);

  log("7/8", `PATCH /notifications/${notifId}/read`);
  r = await api("PATCH", `/notifications/${notifId}/read`, { token });
  if (r.status !== 200 || !r.json.data?.isRead) {
    fail(`Mark read: ${JSON.stringify(r.json)}`);
  }
  ok("Okundu işaretlendi");

  log("8/8", "PATCH /notifications/read-all");
  r = await api("PATCH", "/notifications/read-all", { token });
  if (r.status !== 200) fail(`Read all: ${JSON.stringify(r.json)}`);
  ok(`Güncellenen: ${r.json.data.updated}`);

  console.log("\n========================================");
  console.log(" Bildirim modülü demo — TÜM ADIMLAR BAŞARILI");
  console.log("========================================");
  console.log(` Test hesabı: ${email}`);
  console.log(` Şifre: ${PASSWORD}`);
  console.log(` Postman baseUrl: ${BASE}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
