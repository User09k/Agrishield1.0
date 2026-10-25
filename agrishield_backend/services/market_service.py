"""
Market Service — Indore Mandi Prices via Google Gemini AI
==========================================================
Fetches AI-generated realistic mandi prices for Indore market.
Falls back to curated static data when Gemini is unavailable.
Official Govt Reference: https://mpeuparjan.nic.in/
"""

import json
import re
from datetime import datetime

try:
    from services.gemini_client import call_gemini
except ImportError:
    try:
        from gemini_client import call_gemini
    except ImportError:
        call_gemini = None


# ── Indore Mandi: Govt website for official prices ──
INDORE_MANDI_GOVT_URL = "https://mpeuparjan.nic.in/"

GEMINI_MARKET_PROMPT = """You are an expert agricultural market analyst for Madhya Pradesh, India.
Generate realistic and accurate current mandi (market) prices for Indore Mandi today: {date}.

Return ONLY a valid JSON array (no markdown, no explanation) with exactly 12 items.
Each item must have these fields:
- crop_name: String (crop name in English, common Indian name)
- current_price: String (modal/average price per quintal in INR, realistic today's rate)
- min_price: String (minimum price per quintal in INR)
- max_price: String (maximum price per quintal in INR)
- unit: "Quintal"
- trend: One of "↑ Up", "↓ Down", "→ Stable"
- market_name: "Indore Mandi, MP"
- last_updated: "{date}"

Use these crops (Indore/MP region specific):
Soyabean, Wheat, Maize, Cotton, Chana (Gram), Mustard, Onion, Garlic, Lentil (Masoor), Urad Dal, Moong Dal, Toor Dal

Prices must be realistic for Indore mandi in 2024-2025:
- Soyabean: 4200-5200
- Wheat: 2300-2800
- Maize: 1800-2400
- Cotton: 6500-8000
- Chana: 4800-6000
- Mustard: 5000-6500
- Onion: 800-2500
- Garlic: 6000-12000
- Masoor: 5500-7500
- Urad: 6000-8500
- Moong: 7000-9000
- Toor: 6500-9000

Return ONLY the JSON array, nothing else."""


def get_market_prices():
    """Fetch AI-generated Indore mandi prices using Google Gemini."""
    today = datetime.now().strftime("%d %b %Y")

    # ── Try Gemini AI ──
    if call_gemini is not None:
        try:
            prompt = GEMINI_MARKET_PROMPT.format(date=today)
            result = call_gemini(prompt, model=None, max_tokens=1200, tag="MandiPrices")

            if isinstance(result, dict) and result.get("success"):
                response_text = result.get("raw", "")

                # Strip markdown code fences if present
                cleaned = re.sub(r"```(?:json)?|```", "", response_text).strip()

                # Find JSON array
                start = cleaned.find("[")
                end = cleaned.rfind("]")
                if start != -1 and end != -1:
                    json_str = cleaned[start:end + 1]
                    data = json.loads(json_str)

                    if isinstance(data, list) and len(data) > 0:
                        # Validate and normalize fields
                        normalized = []
                        for item in data:
                            if not isinstance(item, dict):
                                continue
                            normalized.append({
                                "crop_name": str(item.get("crop_name", "Unknown")),
                                "current_price": str(item.get("current_price", "N/A")),
                                "min_price": str(item.get("min_price", "")),
                                "max_price": str(item.get("max_price", "")),
                                "unit": str(item.get("unit", "Quintal")),
                                "trend": str(item.get("trend", "→ Stable")),
                                "market_name": str(item.get("market_name", "Indore Mandi, MP")),
                                "last_updated": str(item.get("last_updated", today)),
                                "source": "gemini_ai",
                            })
                        if normalized:
                            print(f"[MarketService] ✅ Gemini returned {len(normalized)} Indore mandi prices")
                            return normalized
        except Exception as e:
            print(f"[MarketService] ⚠️ Gemini AI failed: {e}. Using fallback data.")

    # ── Fallback static data ──
    print("[MarketService] 📋 Using curated fallback Indore mandi data")
    return get_fallback_data()


def get_fallback_data():
    """Curated Indore Mandi fallback prices when Gemini is unavailable."""
    today = datetime.now().strftime("%d %b %Y")
    return [
        {"crop_name": "Soyabean",        "current_price": "4750", "min_price": "4600", "max_price": "4900", "unit": "Quintal", "trend": "↑ Up",     "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Wheat",           "current_price": "2575", "min_price": "2500", "max_price": "2650", "unit": "Quintal", "trend": "→ Stable",  "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Maize",           "current_price": "2100", "min_price": "1950", "max_price": "2250", "unit": "Quintal", "trend": "↑ Up",     "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Cotton",          "current_price": "7200", "min_price": "6800", "max_price": "7600", "unit": "Quintal", "trend": "↓ Down",   "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Chana (Gram)",    "current_price": "5350", "min_price": "5100", "max_price": "5600", "unit": "Quintal", "trend": "↑ Up",     "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Mustard",         "current_price": "5700", "min_price": "5500", "max_price": "5900", "unit": "Quintal", "trend": "→ Stable",  "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Onion",           "current_price": "1600", "min_price": "1200", "max_price": "2100", "unit": "Quintal", "trend": "↓ Down",   "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Garlic",          "current_price": "8800", "min_price": "7500", "max_price": "10200","unit": "Quintal", "trend": "↑ Up",     "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Lentil (Masoor)", "current_price": "6300", "min_price": "6000", "max_price": "6600", "unit": "Quintal", "trend": "→ Stable",  "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Urad Dal",        "current_price": "7200", "min_price": "6800", "max_price": "7600", "unit": "Quintal", "trend": "↑ Up",     "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Moong Dal",       "current_price": "8100", "min_price": "7600", "max_price": "8600", "unit": "Quintal", "trend": "→ Stable",  "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
        {"crop_name": "Toor Dal",        "current_price": "7800", "min_price": "7200", "max_price": "8400", "unit": "Quintal", "trend": "↑ Up",     "market_name": "Indore Mandi, MP", "last_updated": today, "source": "fallback"},
    ]