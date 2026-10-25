"""
AgriShield AI — Advanced Agriculture Services
================================================
Recovery Advisor, ROI Calculator, Market Predictor, AgriBot Chatbot.
All powered by AI via groq_client (Groq + Gemini fallback).
"""

import json
from services.groq_client import (
    call_groq, parse_json_response, extract_json_object, extract_json_array,
    call_groq_json_object, call_groq_json_array,
    GROQ_API_KEY, GROQ_TEXT_MODEL, GROQ_FALLBACK_MODEL,
)


# ══════════════════════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════
# 1. RECOVERY ADVISOR — AI Business Pivot when damage > 50%
# ══════════════════════════════════════════════════════════════

def get_recovery_advice(scan_data: dict, language: str = "en") -> dict:
    """Generate AI-powered recovery plan for damaged crops in requested language."""
    if language == "hi":
        lang_rule = (
            "LANGUAGE REQUIREMENT (CRITICAL):\n"
            "All text fields (damage_level, pivot_title, pivot_description, alternative_options[].name, "
            "alternative_options[].description, immediate_steps, government_schemes) MUST be written in natural, fluent HINDI in DEVANAGARI SCRIPT (हिंदी लिपि).\n"
            "Keep all JSON keys exactly in English as specified."
        )
    else:
        lang_rule = "All explanations and titles must be written in clear English. Keep JSON keys exactly in English."

    prompt = f"""You are AgriShield AI Recovery Advisor — an expert in agricultural crisis management and alternative farming.

{lang_rule}

A farmer's crop has been severely damaged. Analyze and provide a SMART RECOVERY PLAN.

Crop Data:
- Crop: {scan_data.get("crop_name", "Unknown")}
- Health Score: {scan_data.get("health_score", 0)}/100
- Damage: {scan_data.get("damage_percent", 0)}%
- Disease: {scan_data.get("disease", "Unknown")}

You MUST respond with ONLY a valid JSON object (no markdown, no explanation):
{{
  "damage_level": "Severe / Critical / Moderate",
  "pivot_title": "A short title for the recovery plan",
  "pivot_description": "2-3 lines explaining why this pivot makes sense for the farmer",
  "alternative_options": [
    {{
      "name": "Alternative business 1 (e.g., Poultry Farm / मुर्गी पालन, Mushroom Cultivation / मशरूम उत्पादन, Vermicompost / केंचुआ खाद, Bee Keeping / मधुमक्खी पालन)",
      "investment_required": 25000,
      "monthly_income": 15000,
      "setup_days": 30,
      "description": "1-2 lines about this option"
    }},
    {{
      "name": "Alternative business 2",
      "investment_required": 15000,
      "monthly_income": 10000,
      "setup_days": 15,
      "description": "1-2 lines"
    }},
    {{
      "name": "Alternative business 3",
      "investment_required": 10000,
      "monthly_income": 8000,
      "setup_days": 20,
      "description": "1-2 lines"
    }}
  ],
  "loss_without_pivot": 45000,
  "projected_profit_with_pivot": 35000,
  "recovery_timeline_days": 60,
  "immediate_steps": ["Step 1", "Step 2", "Step 3"],
  "government_schemes": ["Relevant scheme 1 for this situation", "Scheme 2"]
}}

RULES:
1. Give REALISTIC Indian farming alternatives based on the damage level
2. All amounts in Indian Rupees (INR)
3. Consider the season and crop type for recommendations
4. Include practical government schemes available in India
"""

    result = call_groq_json_object(prompt, temperature=0.4, max_tokens=2048, tag=f"RecoveryAdvisor[{language}]")
    if "error" in result:
        return {"error": result["error"]}
    return result


# ══════════════════════════════════════════════════════════════
# 2. ROI CALCULATOR — Smart Investment Planner
# ══════════════════════════════════════════════════════════════

def calculate_roi(investment_amount: int, land_size: float, crop_name: str, language: str = "en") -> dict:
    """Calculate ROI distribution for farmer investment in requested language."""
    if language == "hi":
        lang_rule = (
            "LANGUAGE REQUIREMENT (CRITICAL):\n"
            "All category names, descriptions, risk_level, and tips MUST be written in natural HINDI in DEVANAGARI SCRIPT (हिंदी लिपि).\n"
            "Keep all JSON keys exactly in English as specified."
        )
    else:
        lang_rule = "All category names and tips must be written in clear English. Keep JSON keys exactly in English."

    prompt = f"""You are AgriShield AI Investment Advisor — an expert in farm economics and agricultural ROI calculation.

{lang_rule}

Calculate a SMART ROI breakdown for a farmer's investment.

Input:
- Investment Amount: ₹{investment_amount}
- Land Size: {land_size} acres
- Current/Primary Crop: {crop_name if crop_name else "General"}

You MUST respond with ONLY a valid JSON object:
{{
  "total_investment": {investment_amount},
  "land_size_acres": {land_size},
  "roi_breakdown": [
    {{
      "category": "Primary Crop ({crop_name if crop_name else 'General'})",
      "allocation_percent": 40,
      "investment_amount": 20000,
      "expected_return": 35000,
      "roi_percent": 75,
      "timeline_months": 4
    }},
    {{
      "category": "Poultry Farming / मुर्गी पालन",
      "allocation_percent": 25,
      "investment_amount": 12500,
      "expected_return": 22000,
      "roi_percent": 76,
      "timeline_months": 3
    }},
    {{
      "category": "Mushroom Cultivation / मशरूम उत्पादन",
      "allocation_percent": 20,
      "investment_amount": 10000,
      "expected_return": 18000,
      "roi_percent": 80,
      "timeline_months": 2
    }},
    {{
      "category": "Remaining/Emergency Fund / आपातकालीन निधि",
      "allocation_percent": 15,
      "investment_amount": 7500,
      "expected_return": 7500,
      "roi_percent": 0,
      "timeline_months": 0
    }}
  ],
  "total_expected_return": 82500,
  "total_roi_percent": 65,
  "payback_period_months": 6,
  "risk_level": "Low / Medium / High (or Hindi equivalent)",
  "tips": ["Tip 1 for maximizing returns", "Tip 2", "Tip 3"]
}}

RULES:
1. All amounts in Indian Rupees (INR)
2. ROI calculations should be REALISTIC for Indian farming
3. allocation_percent of all categories MUST add up to 100
4. Consider land size for scaling recommendations
5. Give at least 4 diversification categories
"""

    result = call_groq_json_object(prompt, temperature=0.3, max_tokens=2048, tag=f"ROICalculator[{language}]")
    if "error" in result:
        return {"error": result["error"]}
    return result


# ══════════════════════════════════════════════════════════════
# 3. MARKET DEMAND PREDICTOR — High-Value Crop Intelligence
# ══════════════════════════════════════════════════════════════

def get_market_predictions(language: str = "en") -> dict:
    """Get AI-predicted high-value crops with demand scores in requested language."""
    if language == "hi":
        lang_rule = (
            "LANGUAGE REQUIREMENT (CRITICAL):\n"
            "The 'why_trending' and 'category' explanations MUST be written in natural HINDI in DEVANAGARI SCRIPT (हिंदी लिपि).\n"
            "Provide Hindi crop names in 'crop_name_hindi'. Keep JSON keys exactly in English as specified."
        )
    else:
        lang_rule = "All explanations and categories must be written in clear English. Keep JSON keys exactly in English."

    prompt = f"""You are AgriShield AI Market Intelligence — an expert in agricultural market trends and demand forecasting for Indian markets.

{lang_rule}

Predict the TOP 10 high-demand, high-value crops for the NEXT QUARTER in India.

You MUST respond with ONLY a valid JSON array:
[
  {{
    "crop_name": "Dragon Fruit",
    "crop_name_hindi": "ड्रैगन फ्रूट",
    "category": "Exotic Fruit / Spice / Medicinal Herb / Vegetable / Grain",
    "demand_score": 9.5,
    "current_price_per_kg": 250,
    "predicted_price_per_kg": 320,
    "price_growth_percent": 28,
    "quarterly_trend": [200, 230, 260, 320],
    "why_trending": "1-2 lines why this crop is in high demand",
    "best_states": ["Rajasthan", "Maharashtra"],
    "investment_per_acre": 50000,
    "profit_per_acre": 120000
  }}
]

RULES:
1. Include a MIX of: exotic fruits, spices, medicinal herbs, and high-value vegetables
2. demand_score is out of 10 (realistic — not all 9+)
3. All prices in Indian Rupees (INR) per kg
4. quarterly_trend is an array of 4 price points (last 3 months + next quarter prediction)
5. Include at least 8-10 crops
6. Focus on crops with REAL market demand in India
7. Include some unconventional but profitable crops (Moringa, Stevia, Lavender etc.)
"""

    result = call_groq_json_array(
        prompt,
        temperature=0.5,
        max_tokens=4096,
        tag=f"MarketPredictor[{language}]",
    )
    if isinstance(result, dict) and "error" in result:
        return {"error": result["error"]}
    return {"predictions": result}


# ══════════════════════════════════════════════════════════════
# 4. AGRIBOT CHATBOT — Agriculture-Only AI Assistant
# ══════════════════════════════════════════════════════════════

AGRIBOT_SYSTEM_PROMPT = """You are AgriBot — AgriShield AI's expert agriculture assistant chatbot.

STRICT RULES:
1. You ONLY answer questions related to AGRICULTURE, FARMING, CROPS, SOIL, WEATHER, MARKET PRICES, DISEASES, PESTS, FERTILIZERS, IRRIGATION, GOVERNMENT SCHEMES FOR FARMERS, ANIMAL HUSBANDRY, and related topics.
2. If someone asks a NON-AGRICULTURE question, politely refuse and say "Main sirf kheti-baadi se jude sawaalon ka jawab de sakta hoon." (if Hindi) or "I can only answer agriculture-related questions." (if English).
3. You are an EXPERT — give detailed, practical, actionable advice.
4. Include specific product names, dosages, and timelines when relevant.
5. If asked about diseases, give: cause, symptoms, organic solution, and chemical solution.
6. If asked about market prices, give approximate current Indian market rates.
7. RESPOND IN {language} LANGUAGE ONLY.
8. Be friendly and use farmer-friendly language (not too technical).
9. If the farmer describes symptoms, diagnose the likely issue and provide solution.
10. For Hindi responses, use Devanagari script mixed with common farming terms.

You are chatting with an Indian farmer. Help them with all agriculture needs."""


def agri_chat(message: str, language: str = "hi", history: list = None) -> dict:
    """
    Agriculture-only chatbot powered by AI via Groq.
    language: 'hi' for Hindi, 'en' for English
    history: list of {"role": "user"/"assistant", "content": "..."} messages
    """
    lang_full = "HINDI (Devanagari script)" if language == "hi" else "ENGLISH"
    system_prompt = AGRIBOT_SYSTEM_PROMPT.format(language=lang_full)

    # Build conversation with history
    messages = [{"role": "system", "content": system_prompt}]

    if history:
        for h in history[-10:]:  # Keep last 10 messages for context
            messages.append({
                "role": h.get("role", "user"),
                "content": h.get("content", "")
            })

    messages.append({"role": "user", "content": message})

    from services.gemini_client import call_gemini_chat

    result = call_gemini_chat(
        messages=messages,
        temperature=0.6,
        max_tokens=1024,
        timeout=30,
        tag="AgriBot"
    )

    if not result.get("success"):
        return {"error": result.get("error", "AI service unavailable")}

    return {
        "reply": result["reply"],
        "language": language,
        "model": result.get("model", "gemini-2.5-flash-lite"),
    }
