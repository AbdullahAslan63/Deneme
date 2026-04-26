#!/usr/bin/env python3
"""
Test script for /api/auth/register endpoint.
Prompts for name, email, and password, then sends to the API.
"""

import requests

API_URL = "http://localhost:4200/api/auth/register"


def main():
    print("=" * 50)
    print("Register API Test Script")
    print("=" * 50)

    name = input("İsim: ").strip()
    email = input("E-posta: ").strip()
    password = input("Şifre: ").strip()

    if not name or not email or not password:
        print("\n[HATA] Tüm alanlar zorunludur!")
        return

    payload = {
        "name": name,
        "email": email,
        "password": password
    }

    print(f"\n[GÖNDERİLİYOR] {API_URL}")
    print(f"[PAYLOAD] {payload}")

    try:
        response = requests.post(API_URL, json=payload, timeout=10)

        print(f"\n[STATUS] {response.status_code}")
        print(f"[RESPONSE] {response.text}")

    except requests.exceptions.ConnectionError:
        print("\n[HATA] Sunucuya bağlanılamadı. Sunucunun çalıştığından emin olun!")
    except requests.exceptions.Timeout:
        print("\n[HATA] İstek zaman aşımına uğradı.")
    except Exception as e:
        print(f"\n[HATA] {e}")


if __name__ == "__main__":
    main()
