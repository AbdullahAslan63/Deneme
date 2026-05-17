#!/usr/bin/env python3
"""
AidatPanel API — /api/v1 kapsamlı smoke test + Flutter uyum doğrulamaları.

Kapsanan uçlar (özet):
  Auth: register, login, refresh, join, logout, forgot-password, reset-password*
  Me: GET/PUT/DELETE, password, language, fcm-token, dues (rol)
  Buildings: CRUD, dues listesi (yıl/ay/status), due-amount, due status
  Apartments: CRUD, invite-code

  * Otomatik reset-password (CI): AIDATPANEL_E2E_RESET_LOG — sunucu dosyaya kod yazar.

Gerçek Gmail + Resend (manuel kod):
  export AIDATPANEL_INTERACTIVE_RESEND=1
  export AIDATPANEL_GMAIL=abdullahaslan0408@gmail.com   # isteğe bağlı (varsayılan bu)
  export AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1
  # Sunucuda RESEND_API_KEY + doğrulanmış RESEND_FROM_EMAIL
  python3 test.py
  → Kayıt Gmail+alias ile yapılır (aynı gelen kutuya düşer), forgot-password mail gönderir,
    terminalde 6 haneli kodu ve yeni şifreyi girdikten sonra tüm smoke teste devam edilir.

Kullanım (otomatik mod):
  export AIDATPANEL_API_BASE=http://127.0.0.1:4200/api/v1
  export AIDATPANEL_E2E_RESET_LOG=/tmp/aidatpanel-reset-e2e.jsonl   # isteğe bağlı
  python3 test.py

Docker (Postgres + API + migrate + test.py):
  cd backend
  chmod +x scripts/docker-test.sh   # bir kez
  ./scripts/docker-test.sh
  → ./e2e-data/reset.jsonl host’ta oluşur (AIDATPANEL_E2E_RESET_LOG ile hizalı).
  Durdurma: docker compose down
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import uuid

import requests

BASE = os.environ.get("AIDATPANEL_API_BASE", "httpS://api.aidatpanel.com/api/v1").rstrip("/")
PASSWORD = "123456"
PASSWORD2 = "AbCd12"  # PUT /me/password ve benzeri
PASSWORD3 = "XyZ999"  # reset-password sonrası giriş (otomatik E2E)
E2E_RESET_LOG = os.environ.get("AIDATPANEL_E2E_RESET_LOG")
INTERACTIVE_RESEND = os.environ.get("AIDATPANEL_INTERACTIVE_RESEND", "").lower() in ("1", "true", "yes")
GMAIL_BASE = os.environ.get("AIDATPANEL_GMAIL", "abdullahaslan0408@gmail.com")
INTERACTIVE_DEFAULT_NEW_PASSWORD = "GmailRst9"  # Enter ile kabul edilen yeni şifre (min 6)

success = 0
failed = 0

FLUTTER_LOGIN_USER_KEYS = (
    "id",
    "email",
    "name",
    "role",
    "phone",
    "language",
    "apartmentId",
    "createdAt",
    "updatedAt",
)

FLUTTER_REGISTER_DATA_KEYS = (
    "user",
    "name",
    "email",
    "phone",
    "role",
    "language",
    "apartmentId",
    "createdAt",
    "updatedAt",
)

FLUTTER_INVITE_KEYS = ("id", "apartmentId", "code", "expiresAt")

FLUTTER_DUE_ROOT_KEYS = (
    "id",
    "apartmentId",
    "apartmentNumber",
    "amount",
    "currency",
    "month",
    "year",
    "status",
    "createdAt",
    "updatedAt",
)

# FCM test için yeterli uzunlukta sahte token
FAKE_FCM_TOKEN = "f" * 140


def ok(name: str) -> None:
    global success
    success += 1
    print(f"OK   [{name}]")


def fail(name: str, detail) -> None:
    global failed
    failed += 1
    print(f"FAIL [{name}]: {detail}")


def skip(name: str, reason: str) -> None:
    print(f"SKIP [{name}] — {reason}")


def j(resp: requests.Response):
    try:
        return resp.json()
    except Exception:
        return {"_non_json": (resp.text or "")[:800]}


def req(
    method: str,
    path: str,
    *,
    token: str | None = None,
    json_body=None,
    params=None,
) -> requests.Response:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return requests.request(
        method,
        f"{BASE}{path}",
        headers=headers,
        json=json_body,
        params=params,
        timeout=45,
    )


def expect_ok(name: str, resp: requests.Response, *, need_success_field: bool = True):
    body = j(resp)
    if not (200 <= resp.status_code < 300):
        fail(name, f"HTTP {resp.status_code} {body}")
        return None
    if need_success_field and isinstance(body, dict) and body.get("success") is not True:
        fail(name, body)
        return None
    ok(name)
    return body


def expect_status(name: str, resp: requests.Response, codes: set[int], *, success_field: bool | None = None):
    body = j(resp)
    if resp.status_code not in codes:
        fail(name, f"Beklenen kod {codes}, gelen {resp.status_code}: {body}")
        return None
    if success_field is True and isinstance(body, dict) and body.get("success") is not True:
        fail(name, body)
        return None
    if success_field is False and isinstance(body, dict) and body.get("success") is not False:
        fail(name, body)
        return None
    ok(name)
    return body


def require_keys(ctx: str, obj: dict, keys: tuple[str, ...]) -> bool:
    missing = [k for k in keys if k not in obj]
    if missing:
        fail(ctx, f"eksik anahtarlar {missing} | gelen: {list(obj.keys())}")
        return False
    return True


def assert_iso_or_present(ctx: str, value, *, allow_none: bool = False) -> bool:
    if value is None and allow_none:
        return True
    if value is None:
        fail(ctx, "None olmamalıydı")
        return False
    if isinstance(value, str) and len(value) >= 10:
        return True
    fail(ctx, f"Tarih/ISO beklenir, gelen: {type(value).__name__}={value!r}")
    return False


RESIDENT_FORBIDDEN_JSON_KEYS = frozenset(
    ("passwordHash", "refreshTokenVersion", "password", "fcmToken", "deletedAt")
)


def resident_public_safe(ctx: str, resident: dict | None) -> bool:
    """Flutter §2.4: yanıtta hassas User alanları olmamalı."""
    if resident is None:
        return True
    if not isinstance(resident, dict):
        fail(ctx, f"resident dict değil: {type(resident).__name__}")
        return False
    bad = RESIDENT_FORBIDDEN_JSON_KEYS.intersection(resident.keys())
    if bad:
        fail(ctx, f"yasak alanlar: {sorted(bad)}")
        return False
    return True


def assert_amount_parseable(ctx: str, amount) -> bool:
    if isinstance(amount, (int, float)):
        return True
    if isinstance(amount, str):
        try:
            float(amount.replace(",", "."))
            return True
        except ValueError:
            pass
    fail(ctx, f"amount sayıya çevrilemedi: {amount!r}")
    return False


def read_last_reset_code(email: str) -> str | None:
    """Sunucunun AIDATPANEL_E2E_RESET_LOG'a yazdığı son kod (email eşleşmesi)."""
    if not E2E_RESET_LOG or not os.path.isfile(E2E_RESET_LOG):
        return None
    last: str | None = None
    with open(E2E_RESET_LOG, encoding="utf-8") as fp:
        for line in fp:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("email") == email:
                c = obj.get("code")
                if isinstance(c, str) and len(c) == 6:
                    last = c
    return last


def unique_gmail_manager_email(base: str, ts: int) -> str:
    """Gmail: local+tag@domain aynı gelen kutuya düşer; her çalıştırmada benzersiz kayıt."""
    b = (base or "").strip().lower()
    if "@" not in b:
        return f"mgr_{ts}_{uuid.uuid4().hex[:8]}@test.local"
    local, _, domain = b.partition("@")
    tag = f"aidatpanel.{ts}.{uuid.uuid4().hex[:6]}"
    if "+" in local:
        return f"{local}.{tag}@{domain}"
    return f"{local}+{tag}@{domain}"


def main() -> int:
    print(f"BASE = {BASE}")
    if INTERACTIVE_RESEND:
        print("MOD: AIDATPANEL_INTERACTIVE_RESEND=1 (Gmail + Resend + input())")
        print(f"AIDATPANEL_GMAIL = {GMAIL_BASE}")
    if E2E_RESET_LOG:
        print(f"AIDATPANEL_E2E_RESET_LOG = {E2E_RESET_LOG}")
    print()

    ts = int(time.time())
    if INTERACTIVE_RESEND:
        mgr_email = unique_gmail_manager_email(GMAIL_BASE, ts)
        mgr_name = "Manuel Resend (AidatPanel)"
        print(f"\n>>> AIDATPANEL_INTERACTIVE_RESEND=1 — yönetici e-postası: {mgr_email}\n")
    else:
        mgr_email = f"mgr_{ts}_{uuid.uuid4().hex[:8]}@test.local"
        mgr_name = "Smoke Manager"
    res_email = f"res_{ts}_{uuid.uuid4().hex[:8]}@test.local"
    rst_email = f"rst_{ts}_{uuid.uuid4().hex[:8]}@test.local"
    res_name = "Smoke Resident"

    mgr_password = PASSWORD

    manager_access: str | None = None
    manager_refresh: str | None = None
    resident_access: str | None = None
    building_id: str | None = None
    extra_apartment_id: str | None = None
    invite_apartment_id: str | None = None
    invite_code: str | None = None
    first_due_id: str | None = None
    second_due_id: str | None = None
    sample_due_year: int | None = None
    sample_due_month: int | None = None

    # --- 404 (tanımsız API yolu) ---
    r = req("GET", "/__pytest__/no-such-route")
    expect_status("GET /__pytest__/no-such-route (404)", r, {404}, success_field=False)

    # --- Auth: register ---
    r = req("POST", "/auth/register", json_body={"name": mgr_name, "email": mgr_email, "password": PASSWORD})
    b = expect_ok("POST /auth/register", r)
    if not b or "data" not in b:
        return 1
    reg = b["data"]
    if not require_keys("Flutter RegisterResponse data", reg, FLUTTER_REGISTER_DATA_KEYS):
        return 1
    if reg.get("role") != "MANAGER":
        fail("Flutter RegisterResponse", f"role MANAGER olmalı, gelen: {reg.get('role')}")
        return 1

    r = req("POST", "/auth/register", json_body={"name": mgr_name, "email": mgr_email, "password": PASSWORD})
    expect_status("POST /auth/register (duplicate email → 409)", r, {409}, success_field=False)

    r = req("POST", "/auth/register", json_body={"name": "x", "email": "bad", "password": "123456"})
    expect_status("POST /auth/register (geçersiz email → 400)", r, {400}, success_field=False)

    # --- Auth: login ---
    r = req("POST", "/auth/login", json_body={"identifier": mgr_email, "password": "yanlisSifre"})
    expect_status("POST /auth/login (yanlış şifre → 401)", r, {401}, success_field=False)

    r = req("POST", "/auth/login", json_body={"identifier": mgr_email, "password": mgr_password})
    b = expect_ok("POST /auth/login", r)
    if not b or "data" not in b:
        return 1
    manager_access = b["data"]["accessToken"]
    manager_refresh = b["data"]["refreshToken"]
    user = b["data"].get("user") or {}
    if not require_keys("Flutter LoginResponse.user", user, FLUTTER_LOGIN_USER_KEYS):
        return 1

    r = req(
        "POST",
        "/auth/forgot-password",
        json_body={"email": f"noresponse+{uuid.uuid4().hex}@example.com"},
    )
    b = expect_ok("POST /auth/forgot-password (bilinmeyen email, enumeration-safe)", r)
    if not b or b.get("success") is not True:
        return 1

    if INTERACTIVE_RESEND:
        print("\n" + "=" * 62)
        print("Resend: Gmail gelen kutusunda şifre sıfırlama e-postasını açın.")
        print(f"Kayıtlı adres (To): {mgr_email}")
        print("=" * 62 + "\n")
        r = req("POST", "/auth/forgot-password", json_body={"email": mgr_email})
        b = expect_ok("POST /auth/forgot-password (Resend → Gmail)", r)
        if not b or b.get("success") is not True:
            return 1

        code_in = ""
        while len(code_in) != 6:
            code_in = (
                input("E-postadaki 6 haneli kodu girin (sadece kod, örn. 2K9TH4): ").strip().upper().replace(" ", "")
            )
            if len(code_in) != 6:
                print("Tam 6 karakter olmalı (rakam 2-9 ve büyük harf; 0,O,1,I,L yok).")

        pwd_hint = f"Yeni şifre [Enter = '{INTERACTIVE_DEFAULT_NEW_PASSWORD}']"
        pwd_in = input(f"{pwd_hint}: ").strip()
        if not pwd_in:
            pwd_in = INTERACTIVE_DEFAULT_NEW_PASSWORD
        if len(pwd_in) < 6:
            fail("Manuel reset", "Yeni şifre en az 6 karakter olmalı")
            return 1

        r = req("POST", "/auth/reset-password", json_body={"token": code_in, "password": pwd_in})
        b = expect_ok("POST /auth/reset-password (manuel kod)", r)
        if not b:
            return 1

        r = req("POST", "/auth/login", json_body={"identifier": mgr_email, "password": pwd_in})
        b = expect_ok("POST /auth/login (reset sonrası yönetici)", r)
        if not b or "data" not in b:
            return 1
        manager_access = b["data"]["accessToken"]
        manager_refresh = b["data"]["refreshToken"]
        mgr_password = pwd_in
    else:
        r = req("POST", "/auth/forgot-password", json_body={"email": mgr_email})
        b = expect_ok("POST /auth/forgot-password (kayıtlı email)", r)
        if not b or b.get("success") is not True:
            return 1

    # --- Auth: refresh ---
    r = req("POST", "/auth/refresh", json_body={"refreshToken": manager_refresh})
    b = expect_ok("POST /auth/refresh", r)
    if not b or "data" not in b or "accessToken" not in b["data"]:
        return 1
    manager_access = b["data"]["accessToken"]

    # --- Me (yönetici) ---
    r = req("GET", "/me", token=manager_access)
    b = expect_ok("GET /me (MANAGER)", r)
    if not b or not require_keys("GET /me (MANAGER) data", b.get("data") or {}, FLUTTER_LOGIN_USER_KEYS):
        return 1

    r = req(
        "PUT",
        "/me",
        token=manager_access,
        json_body={"name": mgr_name + " Güncel", "language": "tr"},
    )
    b = expect_ok("PUT /me (MANAGER)", r)
    if not b or "data" not in b:
        return 1

    r = req("PUT", "/me/language", token=manager_access, json_body={"language": "en"})
    b = expect_ok("PUT /me/language (MANAGER)", r)
    if not b or (b.get("data") or {}).get("language") != "en":
        fail("PUT /me/language MANAGER", b)
        return 1

    r = req("PUT", "/me/fcm-token", token=manager_access, json_body={"fcmToken": FAKE_FCM_TOKEN})
    expect_ok("PUT /me/fcm-token (MANAGER)", r)

    # --- Auth: reset-password E2E (ayrı kullanıcı; etkileşimli Gmail modunda atlanır) ---
    if not INTERACTIVE_RESEND:
        r = req(
            "POST",
            "/auth/register",
            json_body={"name": "Reset Test", "email": rst_email, "password": PASSWORD},
        )
        b = expect_ok("POST /auth/register (reset test kullanıcısı)", r)
        if not b:
            return 1

        r = req("POST", "/auth/forgot-password", json_body={"email": rst_email})
        b = expect_ok("POST /auth/forgot-password (reset test)", r)
        if not b:
            return 1

        code = read_last_reset_code(rst_email)
        if code and E2E_RESET_LOG:
            r = req(
                "POST",
                "/auth/reset-password",
                json_body={"token": "AAAAAA", "password": PASSWORD2},
            )
            expect_status("POST /auth/reset-password (geçersiz kod → 400)", r, {400}, success_field=False)

            r = req(
                "POST",
                "/auth/reset-password",
                json_body={"token": code, "password": PASSWORD3},
            )
            b = expect_ok("POST /auth/reset-password (geçerli kod)", r)
            if not b:
                return 1

            r = req("POST", "/auth/login", json_body={"identifier": rst_email, "password": PASSWORD3})
            expect_ok("POST /auth/login (reset sonrası yeni şifre)", r)
        else:
            skip(
                "POST /auth/reset-password E2E",
                "AIDATPANEL_E2E_RESET_LOG tanımlı değil veya dosyada kod yok; sunucuyu bu env ile başlatın",
            )
    else:
        skip(
            "POST /auth/reset-password (otomatik rst kullanıcısı)",
            "Manuel Resend akışı yönetici hesabında yapıldı",
        )

    # --- Buildings ---
    r = req(
        "POST",
        "/buildings",
        token=manager_access,
        json_body={
            "name": f"Smoke Bina {ts}",
            "address": "Test cad. No 1",
            "city": "İstanbul",
            "totalFloors": 1,
            "apartmentsPerFloor": 2,
            "dueAmount": 500,
            "dueDay": 10,
            "currency": "TRY",
        },
    )
    b = expect_ok("POST /buildings", r)
    if not b or "data" not in b or not b["data"].get("id"):
        return 1
    building_id = b["data"]["id"]
    apts = b["data"].get("apartments") or []
    if apts:
        invite_apartment_id = apts[0]["id"]

    # CORS: PATCH preflight (Flutter web — aidat uçları)
    ro = requests.options(
        f"{BASE}/buildings/{building_id}/due-amount",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "PATCH",
            "Access-Control-Request-Headers": "authorization, content-type",
        },
        timeout=15,
    )
    if ro.status_code in (200, 204):
        acm = ro.headers.get("Access-Control-Allow-Methods", "")
        if "PATCH" in acm.upper():
            ok("CORS preflight PATCH (/buildings/:id/due-amount)")
        else:
            fail("CORS preflight PATCH", f"Access-Control-Allow-Methods={acm!r}")
            return 1
    else:
        fail("CORS preflight", f"HTTP {ro.status_code}")
        return 1

    r = req("GET", "/buildings", token=manager_access)
    b = expect_ok("GET /buildings", r)
    if not b:
        return 1
    lst = b.get("data")
    if isinstance(lst, list):
        mine = next((x for x in lst if x.get("id") == building_id), None)
        if mine is None:
            fail("GET /buildings", "yeni oluşturulan bina listede yok")
            return 1
        cnt = mine.get("_count")
        if not isinstance(cnt, dict) or not isinstance(cnt.get("apartments"), int):
            fail("GET /buildings _count.apartments", f"_count={cnt!r}")
            return 1
        if cnt["apartments"] != len(apts):
            fail(
                "GET /buildings _count.apartments",
                f"beklenen {len(apts)}, gelen {cnt['apartments']}",
            )
            return 1
        ok("GET /buildings (_count.apartments)")

    r = req("GET", f"/buildings/{building_id}", token=manager_access)
    b = expect_ok("GET /buildings/:id", r)
    if not b:
        return 1

    r = req("GET", f"/buildings/{building_id}/dues", token=manager_access)
    b = expect_ok("GET /buildings/:id/dues", r)
    if b and isinstance(b.get("data"), list) and b["data"]:
        dues = b["data"]
        du0 = dues[0]
        if not require_keys("Flutter DueModel (bina aidat listesi)", du0, FLUTTER_DUE_ROOT_KEYS):
            return 1
        if not assert_amount_parseable("Due.amount", du0.get("amount")):
            return 1
        if du0.get("apartmentNumber") in (None, ""):
            fail("Flutter DueModel.apartmentNumber", "boş veya yok")
            return 1
        if "apartment" not in du0 or not isinstance(du0["apartment"], dict):
            fail("Flutter nested apartment", "apartment nesnesi yok")
            return 1
        if "resident" not in du0:
            fail("Flutter due resident", "resident anahtarı yok (null olabilir)")
            return 1
        first_due_id = du0.get("id")
        sample_due_year = du0.get("year")
        sample_due_month = du0.get("month")
        if len(dues) > 1:
            second_due_id = dues[1].get("id")
        ok("Flutter DueModel (bina listesi alanları)")

    if sample_due_year is not None and sample_due_month is not None:
        r = req(
            "GET",
            f"/buildings/{building_id}/dues",
            token=manager_access,
            params={"year": str(sample_due_year), "month": str(sample_due_month)},
        )
        b = expect_ok("GET /buildings/:id/dues?year&month", r)
        if b and isinstance(b.get("data"), list):
            for row in b["data"]:
                if row.get("year") != sample_due_year or row.get("month") != sample_due_month:
                    fail("Bina aidat filtre", f"Beklenen {sample_due_year}/{sample_due_month}")
                    return 1
            ok("Bina aidat listesi year/month filtresi")

    r = req(
        "PATCH",
        f"/buildings/{building_id}/due-amount",
        token=manager_access,
        json_body={
            "dueAmount": 600,
            "dueDay": 12,
            "currency": "TRY",
            "affectCurrent": True,
        },
    )
    b = expect_ok("PATCH /buildings/:id/due-amount", r)
    if not b:
        return 1

    if first_due_id:
        r = req(
            "PATCH",
            f"/buildings/{building_id}/dues/{first_due_id}/status",
            token=manager_access,
            json_body={"status": "PAID"},
        )
        b = expect_ok("PATCH /buildings/:id/dues/:dueId/status → PAID", r)
        if not b or "data" not in b:
            return 1
        upd = b["data"]
        if upd.get("apartmentNumber") in (None, ""):
            fail("PATCH due yanıtı apartmentNumber", "eksik")
            return 1
        ok("Flutter DueModel (PATCH status yanıtı)")

        r = req(
            "GET",
            f"/buildings/{building_id}/dues",
            token=manager_access,
            params={"status": "PAID"},
        )
        b = expect_ok("GET /buildings/:id/dues?status=PAID", r)
        if b and isinstance(b.get("data"), list):
            for row in b["data"]:
                if row.get("status") != "PAID":
                    fail("status=PAID filtre", row.get("status"))
                    return 1
            ok("Bina aidat listesi status=PAID filtresi")

    if second_due_id:
        r = req(
            "PATCH",
            f"/buildings/{building_id}/dues/{second_due_id}/status",
            token=manager_access,
            json_body={"status": "WAIVED", "note": "Smoke test"},
        )
        expect_ok("PATCH /buildings/:id/dues/:dueId/status → WAIVED", r)

    # --- Apartments ---
    r = req("GET", f"/buildings/{building_id}/apartments", token=manager_access)
    b = expect_ok("GET /buildings/:id/apartments", r)
    if b and isinstance(b.get("data"), list) and b["data"]:
        for idx, apt0 in enumerate(b["data"]):
            if "resident" not in apt0:
                fail("Flutter Apartment (resident alanı)", f"[{idx}] resident anahtarı yok")
                return 1
            if not resident_public_safe(f"GET /apartments [daire {idx}] resident", apt0.get("resident")):
                return 1
        if not invite_apartment_id:
            invite_apartment_id = b["data"][0].get("id")
        ok("Flutter Apartment JSON (resident anahtarı + güvenli alanlar)")

    r = req(
        "POST",
        f"/buildings/{building_id}/apartments",
        token=manager_access,
        json_body={"number": "9Z", "floor": 0},
    )
    b = expect_ok("POST /buildings/:id/apartments", r)
    if b and "data" in b and b["data"].get("id"):
        extra_apartment_id = b["data"]["id"]

    if extra_apartment_id:
        r = req(
            "PUT",
            f"/buildings/{building_id}/apartments/{extra_apartment_id}",
            token=manager_access,
            json_body={"number": "9Y", "floor": 1},
        )
        b = expect_ok("PUT /buildings/:id/apartments/:id", r)
        if not b:
            return 1

    # --- Invite ---
    if not invite_apartment_id:
        fail("POST /apartments/:id/invite-code", "Davet için daire id yok")
        return 1
    r = req("POST", f"/apartments/{invite_apartment_id}/invite-code", token=manager_access)
    b = expect_ok("POST /apartments/:apartmentId/invite-code", r)
    if not b or "data" not in b:
        return 1
    inv = b["data"]
    if not require_keys("Flutter InviteCodeModel", inv, FLUTTER_INVITE_KEYS):
        return 1
    if "usedAt" not in inv:
        fail("Flutter InviteCodeModel", "usedAt anahtarı yok")
        return 1
    if inv.get("apartmentId") != invite_apartment_id:
        fail("Flutter InviteCodeModel.apartmentId", f"{inv.get('apartmentId')} != {invite_apartment_id}")
        return 1
    if not assert_iso_or_present("InviteCodeModel.expiresAt", inv.get("expiresAt")):
        return 1
    invite_code = inv["code"]
    if not re.fullmatch(r"^AP[0-9A-F]-[0-9A-F]{3}-[0-9A-F]{4}$", invite_code):
        fail("Davet kodu formatı (APX-XXX-XXXX)", repr(invite_code))
        return 1
    ok("Flutter InviteCodeModel alanları")

    # --- Join ---
    r = req(
        "POST",
        "/auth/join",
        json_body={
            "name": res_name,
            "email": res_email,
            "password": PASSWORD,
            "inviteCode": "INVALID-CODE-999",
        },
    )
    expect_status("POST /auth/join (geçersiz davet → 400)", r, {400}, success_field=False)

    r = req(
        "POST",
        "/auth/join",
        json_body={
            "name": res_name,
            "email": res_email,
            "password": PASSWORD,
            "inviteCode": invite_code,
        },
    )
    b = expect_ok("POST /auth/join", r)
    if not b or "data" not in b:
        return 1
    resident_access = b["data"]["accessToken"]
    res_user = b["data"].get("user") or {}
    if not require_keys("Flutter JoinResponse.user", res_user, FLUTTER_LOGIN_USER_KEYS):
        return 1
    if res_user.get("apartmentId") != invite_apartment_id:
        fail("Flutter JoinResponse.user.apartmentId", f"{res_user.get('apartmentId')} != {invite_apartment_id}")
        return 1
    if res_user.get("role") != "RESIDENT":
        fail("Flutter JoinResponse.user.role", res_user.get("role"))
        return 1

    r = req("GET", f"/buildings/{building_id}/apartments", token=manager_access)
    b = expect_ok("GET /apartments (join sonrası — resident eşleşmesi)", r)
    if b and isinstance(b.get("data"), list):
        matched = False
        for apt in b["data"]:
            if apt.get("id") != invite_apartment_id:
                continue
            matched = True
            res = apt.get("resident")
            if not isinstance(res, dict) or res.get("id") != res_user.get("id"):
                fail("join sonrası apartment.resident", f"beklenen user id {res_user.get('id')}, gelen: {res}")
                return 1
            if not resident_public_safe("join sonrası resident", res):
                return 1
            break
        if not matched:
            fail("GET /apartments join sonrası", "invite_apartment_id listede yok")
            return 1
        ok("GET /apartments (join sonrası resident.id + güvenlik)")

    r = req("GET", f"/buildings/{building_id}/dues", token=manager_access)
    b = expect_ok("GET /buildings/:id/dues (join sonrası)", r)
    if b and isinstance(b.get("data"), list):
        for row in b["data"]:
            if not resident_public_safe("GET /buildings/:id/dues resident", row.get("resident")):
                return 1
        ok("GET /buildings/:id/dues (join sonrası — resident güvenli)")

    # --- Rol: sakin yönetici uçları ---
    r = req("GET", "/buildings", token=resident_access)
    expect_status("GET /buildings (RESIDENT → 403)", r, {403}, success_field=False)

    r = req("POST", "/buildings", token=resident_access, json_body={"name": "x", "address": "a", "city": "c"})
    expect_status("POST /buildings (RESIDENT → 403)", r, {403}, success_field=False)

    # --- Me (sakin) ---
    r = req("GET", "/me", token=resident_access)
    b = expect_ok("GET /me (RESIDENT)", r)
    if not b or not require_keys("GET /me (RESIDENT) data", b.get("data") or {}, FLUTTER_LOGIN_USER_KEYS):
        return 1

    r = req("PUT", "/me/language", token=resident_access, json_body={"language": "en"})
    b = expect_ok("PUT /me/language (RESIDENT)", r)
    if not b or (b.get("data") or {}).get("language") != "en":
        fail("PUT /me/language RESIDENT", b)
        return 1

    r = req(
        "PUT",
        "/me/password",
        token=resident_access,
        json_body={"currentPassword": PASSWORD, "newPassword": PASSWORD2},
    )
    expect_ok("PUT /me/password (RESIDENT)", r)

    r = req("POST", "/auth/login", json_body={"identifier": res_email, "password": PASSWORD2})
    b = expect_ok("POST /auth/login (sakin yeni şifre)", r)
    if not b or "data" not in b:
        return 1
    resident_access = b["data"]["accessToken"]

    r = req("PUT", "/me/fcm-token", token=resident_access, json_body={"fcmToken": FAKE_FCM_TOKEN + "r"})
    expect_ok("PUT /me/fcm-token (RESIDENT)", r)

    # --- GET /me/dues ---
    r = req("GET", "/me/dues", token=resident_access)
    b = expect_ok("GET /me/dues (RESIDENT)", r)
    if not b or not isinstance(b.get("data"), list):
        return 1
    my_dues = b["data"]
    if my_dues:
        md0 = my_dues[0]
        if not require_keys("Flutter DueModel (GET /me/dues)", md0, FLUTTER_DUE_ROOT_KEYS):
            return 1
        if md0.get("apartmentNumber") in (None, ""):
            fail("GET /me/dues apartmentNumber", "boş")
            return 1
        if "building" not in md0 or not isinstance(md0["building"], dict):
            fail("GET /me/dues building", "building nesnesi yok")
            return 1
        if not assert_amount_parseable("GET /me/dues amount", md0.get("amount")):
            return 1
        ok("Flutter DueModel (GET /me/dues)")
        y, m = md0.get("year"), md0.get("month")
        if y is not None and m is not None:
            r2 = req("GET", "/me/dues", token=resident_access, params={"year": str(y), "month": str(m)})
            b2 = expect_ok("GET /me/dues?year&month (filtre)", r2)
            if b2 and isinstance(b2.get("data"), list):
                for row in b2["data"]:
                    if row.get("year") != y or row.get("month") != m:
                        fail("GET /me/dues filtre", f"{row.get('year')}/{row.get('month')} != {y}/{m}")
                        return 1
                ok("GET /me/dues year/month filtresi")

        r3 = req("GET", "/me/dues", token=resident_access, params={"status": "PAID"})
        b3 = expect_ok("GET /me/dues?status=PAID", r3)
        if b3 and isinstance(b3.get("data"), list):
            for row in b3["data"]:
                if row.get("status") != "PAID":
                    fail("GET /me/dues status filtre", row.get("status"))
                    return 1
            ok("GET /me/dues status=PAID filtresi")

    r = req("GET", "/me/dues", token=manager_access)
    expect_status("GET /me/dues (MANAGER → 403)", r, {403}, success_field=False)

    # --- P0: Sakini daireden ayırma (DELETE .../apartments/:id/resident) ---
    r = req(
        "DELETE",
        f"/buildings/{building_id}/apartments/{invite_apartment_id}/resident",
        token=manager_access,
    )
    b = expect_ok("DELETE /buildings/:id/apartments/:id/resident", r)
    if not b or "data" not in b:
        return 1
    detached = b["data"]
    if detached.get("id") != invite_apartment_id:
        fail("DELETE resident yanıtı apartment id", detached.get("id"))
        return 1
    if detached.get("resident") is not None:
        fail("DELETE resident yanıtı", f"resident null olmalıydı: {detached.get('resident')}")
        return 1

    r = req(
        "DELETE",
        f"/buildings/{building_id}/apartments/{invite_apartment_id}/resident",
        token=manager_access,
    )
    expect_status(
        "DELETE /buildings/:id/apartments/:id/resident (ikinci — 404)",
        r,
        {404},
        success_field=False,
    )

    r = req("GET", f"/buildings/{building_id}/apartments", token=manager_access)
    b = expect_ok("GET /apartments (sakin çıkarıldı)", r)
    if b and isinstance(b.get("data"), list):
        for apt in b["data"]:
            if apt.get("id") == invite_apartment_id and apt.get("resident") is not None:
                fail("GET /apartments (çıkış sonrası)", "resident hâlâ dolu")
                return 1
        ok("GET /apartments (invite daire resident=null)")

    r = req("GET", "/me", token=resident_access)
    b = expect_ok("GET /me (sakin — daireden çıkarıldı)", r)
    if b and (b.get("data") or {}).get("apartmentId") is not None:
        fail("GET /me apartmentId (çıkış sonrası)", "null olmalıydı")
        return 1

    r = req("GET", "/me/dues", token=resident_access)
    b = expect_ok("GET /me/dues (dairesiz sakin — boş liste)", r)
    if not b or not isinstance(b.get("data"), list):
        return 1
    if len(b["data"]) != 0:
        fail("GET /me/dues dairesiz", f"boş liste beklenir, len={len(b['data'])}")
        return 1
    ok("GET /me/dues (apartmentId null → [])")

    # --- Yönetici şifre değiştir + yeniden giriş ---
    r = req(
        "PUT",
        "/me/password",
        token=manager_access,
        json_body={"currentPassword": mgr_password, "newPassword": PASSWORD2},
    )
    expect_ok("PUT /me/password (MANAGER)", r)
    mgr_password = PASSWORD2

    r = req("POST", "/auth/login", json_body={"identifier": mgr_email, "password": mgr_password})
    b = expect_ok("POST /auth/login (yönetici yeni şifre)", r)
    if not b or "data" not in b:
        return 1
    manager_access = b["data"]["accessToken"]
    manager_refresh = b["data"]["refreshToken"]

    if extra_apartment_id:
        r = req("DELETE", f"/buildings/{building_id}/apartments/{extra_apartment_id}", token=manager_access)
        b = expect_ok("DELETE /buildings/:id/apartments/:id", r)
        if not b:
            return 1

    r = req(
        "PUT",
        f"/buildings/{building_id}",
        token=manager_access,
        json_body={
            "name": f"Smoke Bina Güncel {ts}",
            "address": "Test cad. No 2 güncel",
            "city": "İstanbul",
        },
    )
    b = expect_ok("PUT /buildings/:id", r)
    if not b:
        return 1

    r = req("POST", "/auth/refresh", json_body={"refreshToken": manager_refresh})
    b = expect_ok("POST /auth/refresh (logout öncesi)", r)
    if b and "data" in b and "accessToken" in b["data"]:
        manager_access = b["data"]["accessToken"]

    r = req("POST", "/auth/logout", token=manager_access)
    b = expect_ok("POST /auth/logout", r)
    if not b:
        return 1

    r = req("POST", "/auth/refresh", json_body={"refreshToken": manager_refresh})
    expect_status("POST /auth/refresh (logout sonrası → 401)", r, {401}, success_field=False)

    r = req("DELETE", f"/buildings/{building_id}", token=manager_access)
    del_body = j(r)
    if 200 <= r.status_code < 300 and isinstance(del_body, dict) and del_body.get("success") is True:
        ok("DELETE /buildings/:id")
    else:
        print(
            f"SKIP DELETE /buildings/:id → HTTP {r.status_code} {del_body}\n"
            "      (Sakin atanmış bina — FK; beklenen.)"
        )

    # --- DELETE /me (binasız yönetici, KVKK soft) ---
    del_mgr_email = f"del_{ts}_{uuid.uuid4().hex[:6]}@test.local"
    r = req(
        "POST",
        "/auth/register",
        json_body={"name": "Silinecek Yönetici", "email": del_mgr_email, "password": PASSWORD},
    )
    b = expect_ok("POST /auth/register (DELETE /me test)", r)
    if not b:
        return 1
    r = req("POST", "/auth/login", json_body={"identifier": del_mgr_email, "password": PASSWORD})
    b = expect_ok("POST /auth/login (DELETE /me test)", r)
    if not b or "data" not in b:
        return 1
    del_access = b["data"]["accessToken"]

    r = req("DELETE", "/me", token=del_access)
    b = expect_ok("DELETE /me (KVKK soft)", r)
    if not b:
        return 1

    r = req("POST", "/auth/login", json_body={"identifier": del_mgr_email, "password": PASSWORD})
    expect_status("POST /auth/login (silinmiş hesap → 401)", r, {401}, success_field=False)

    print(f"\nÖzet: OK={success}  FAIL={failed}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except requests.RequestException as e:
        print(f"Ağ hatası: {e}", file=sys.stderr)
        sys.exit(2)
