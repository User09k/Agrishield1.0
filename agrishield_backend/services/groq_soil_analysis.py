"""
Soil Analysis Service
=====================
Uses groq_client for all API calls.
"""

from services.groq_client import call_groq_json_object, call_groq_json_array


# =====================================================
def get_soil_prompt(language: str = "en") -> str:
    if language == "hi":
        lang_rule = (
            "LANGUAGE INSTRUCTION (STRICT):\n"
            "The 'advisory' field and all descriptions MUST be written in fluent, natural HINDI in DEVANAGARI SCRIPT (हिंदी लिपि).\n"
            "Provide Hindi name for 'soil_type_hindi' (e.g. काली मिट्टी, दोमट मिट्टी, बलुई मिट्टी, लाल मिट्टी).\n"
            "Keep all JSON keys exactly in English as specified."
        )
        adv_example = "मिट्टी की गुणवत्ता सुधारने के लिए 2-3 पंक्तियों में व्यावहारिक सलाह"
    else:
        lang_rule = "All explanations and advisory MUST be written in clear English. Keep JSON keys exactly in English."
        adv_example = "2-3 lines of practical improvement advice in English"

    return f"""You are an expert agricultural soil scientist. Look at this image carefully.

{lang_rule}

IMPORTANT: First determine if this image actually shows SOIL or GROUND/EARTH. 
If the image is NOT soil (e.g. a person, animal, building, food, random object, selfie, document, text etc.), you MUST respond with:
{{"is_soil": false, "error": "This is not a soil image. Please upload a clear photo of soil or ground."}}

If it IS a soil image, respond with ONLY this JSON:
{{
  "is_soil": true,
  "soil_type": "Clay / Sandy / Loamy / Silty / Peaty / Chalky / Laterite / Black Cotton / Red / Alluvial",
  "soil_type_hindi": "Hindi name of soil type (हिंदी में नाम)",
  "ph_level": "estimated pH (e.g., Slightly Acidic - 6.0-6.5)",
  "soil_texture": "Fine-grained / Medium-grained / Coarse",
  "soil_color": "observed color",
  "soil_health": "Good / Fair / Poor",
  "health_score": 75,
  "moisture_level": "Dry / Moderate / Wet",
  "organic_matter": "Low / Medium / High",
  "composition": "detailed soil composition",
  "nitrogen_level": "Low / Medium / High",
  "phosphorus_level": "Low / Medium / High",
  "potassium_level": "Low / Medium / High",
  "advisory": "{adv_example}"
}}

Respond with ONLY the JSON, no extra text."""


def analyze_soil_image(image_path, language: str = "en"):
    """Analyze a soil image using Gemini Vision API."""
    prompt = get_soil_prompt(language)
    result = call_groq_json_object(
        prompt,
        images=[image_path],
        temperature=0.3,
        max_tokens=1024,
        timeout=60,
        tag=f"SoilAnalysis[{language}]",
    )

    if "error" in result and "is_soil" not in result:
        return result

    # Check if image was rejected as non-soil
    if result.get("is_soil") == False:
        err = "यह मिट्टी की तस्वीर नहीं है। कृपया मिट्टी की साफ तस्वीर अपलोड करें।" if language == "hi" else "This is not a soil image. Please upload a clear photo of soil."
        return {"error": result.get("error", err)}

    return result


# =====================================================
# 2. PLANT RECOMMENDATIONS (Pot / Gamla / Home Garden)
# =====================================================
def get_plant_recommendations(soil_data, language: str = "en"):
    """Get pot/garden plant recommendations based on soil data."""
    soil_info = _format_soil_info(soil_data)

    if language == "hi":
        lang_instruct = (
            "LANGUAGE REQUIREMENT (CRITICAL):\n"
            "All descriptions, care_steps, benefits, planting_method, soil_preparation, "
            "common_diseases, sunlight_needs, water_needs, and harvest_info MUST be written in natural, fluent HINDI using DEVANAGARI SCRIPT (हिंदी लिपि).\n"
            "Keep JSON keys exactly in English as defined below."
        )
    else:
        lang_instruct = "All descriptions and care steps must be written in clear English. Keep JSON keys exactly in English."

    prompt = f"""You are an expert Indian horticulture and home gardening advisor.

{lang_instruct}

Based on this soil analysis, recommend 20-25 PLANTS that can be grown in POTS, CONTAINERS, GAMLA, HOME GARDEN, TERRACE GARDEN or BALCONY.

{soil_info}

CRITICAL RULES:
- IMPORTANT: List ALL FLOWER plants FIRST in the array, then other types after flowers.
- Include at least 8-10 FLOWER plants like Rose, Marigold, Jasmine, Hibiscus, Sunflower, Lily, Dahlia, Mogra, Champa, Sadabahar, Bougainvillea, Rajnigandha, Chameli, Genda, Gulmohar etc.
- Then include herbs, medicinal plants, ornamental plants, small vegetables (tomato, chili, mint, tulsi, etc.)
- ONLY recommend plants that can be grown in POTS/GAMLA/HOME GARDEN
- DO NOT recommend field crops like wheat, rice, sugarcane, cotton, soybean etc. Those belong in CROPS section.
- Rate each plant: Excellent (best match), Good (grows well), Moderate (will survive)
- All benefits from FARMER/GROWER perspective (easy to maintain, saves money, medicinal value, sells well in local market)
- Give as many plants as possible, minimum 20

Respond with ONLY a valid JSON array:
[
  {{
    "plant_name": "English Name",
    "plant_name_hindi": "Hindi Name (हिंदी नाम)",
    "suitability": "Excellent / Good / Moderate",
    "plant_type": "Flower / Vegetable / Herb / Medicinal / Ornamental / Fruit",
    "growth_days": 90,
    "plant_age_info": "Seedling: 0-15 days, Vegetative: 15-45 days, Flowering: 45-75 days, Fruiting: 75-90 days",
    "sunlight_needs": "Sunlight requirement",
    "water_needs": "Watering requirement",
    "fertilizer_needs": "Fertilizer dosage per plant",
    "soil_preparation": "How to prepare pot/gamla soil mix",
    "planting_method": "Step by step planting in pot/gamla",
    "care_steps": ["Step 1", "Step 2", "Step 3", "Step 4"],
    "common_diseases": "Common diseases and prevention",
    "harvest_info": "When and how to harvest or enjoy",
    "benefits": ["Benefit 1", "Benefit 2"],
    "best_season": "October-November (Rabi)",
    "difficulty_level": "Easy / Medium / Hard",
    "description": "2-3 lines about this plant for home/pot growing"
  }}
]

REMEMBER: Flower plants MUST come FIRST in the array. Give REALISTIC Indian home garden data. Respond with ONLY JSON array."""

    result = call_groq_json_array(
        prompt,
        temperature=0.4,
        max_tokens=8192,
        timeout=120,
        tag=f"PlantRecommendations[{language}]",
    )

    if isinstance(result, dict) and "error" in result:
        return result
    return {"plants": result}


# =====================================================
# 3. CROP RECOMMENDATIONS (Field-level farming)
# =====================================================
def get_crop_recommendations(soil_data, image_paths, season=None, language: str = "en"):
    """Get field crop recommendations using soil data + field photos."""
    if len(image_paths) < 3:
        return {"error": "Minimum 3 field photos required"}

    soil_info = _format_soil_info(soil_data)

    # Build season filter instruction
    season_filter = ""
    if season:
        season_map = {
            "winter": "ONLY recommend RABI / WINTER season crops like Wheat, Mustard, Gram (Chana), Peas, Barley, Lentil (Masoor), Chickpea, Linseed, Safflower, Fenugreek (Methi), Coriander, Cumin, Potato, Onion, Garlic, Carrot, Radish, Spinach, Cauliflower, Cabbage, Broccoli, Beetroot, Turnip, Fennel (Saunf). DO NOT include any Kharif or Zaid crops.",
            "summer": "ONLY recommend ZAID / SUMMER season crops like Watermelon, Muskmelon, Cucumber, Moong (Green Gram), Urad, Sunflower, Groundnut (Summer), Sesame, Pumpkin, Bottle Gourd, Bitter Gourd, Ridge Gourd, Sponge Gourd, Okra (Lady Finger), Tomato, Brinjal, Capsicum, Maize (Summer), Cowpea (Lobia), Cluster Bean. DO NOT include any Kharif or Rabi crops.",
            "rainy": "ONLY recommend KHARIF / RAINY season crops like Rice (Paddy), Maize, Soybean, Cotton, Sugarcane, Bajra (Pearl Millet), Jowar (Sorghum), Arhar/Tur Dal, Urad (Kharif), Moong (Kharif), Groundnut, Sesame, Castor, Jute, Turmeric, Ginger, Chilli, Sorghum, Ragi, Foxtail Millet, Barnyard Millet. DO NOT include any Rabi or Zaid crops."
        }
        season_filter = season_map.get(season.lower(), "")

    if language == "hi":
        lang_instruct = (
            "LANGUAGE REQUIREMENT (CRITICAL):\n"
            "All descriptions, soil_preparation_steps, fertilizer_schedule, irrigation_schedule, "
            "pesticide_needs, weed_management, benefits, drawbacks, growth_requirements, harvest_method, "
            "and market_demand MUST be written in natural, fluent HINDI using DEVANAGARI SCRIPT (हिंदी लिपि).\n"
            "Keep JSON keys exactly in English as defined below."
        )
    else:
        lang_instruct = "All descriptions, schedules, and tips must be written in clear English. Keep JSON keys exactly in English."

    prompt = f"""You are an expert Indian agricultural scientist advising FARMERS for FIELD-LEVEL FARMING.

{lang_instruct}

Analyze these {len(image_paths)} field photos with soil data to recommend 20-25 BEST FIELD CROPS.

SOIL DATA:
{soil_info}

{f"SEASON FILTER: {season_filter}" if season_filter else ""}

CRITICAL RULES:
- ONLY recommend FIELD CROPS grown on agricultural land/farms
{f"- {season_filter}" if season_filter else "- Include crops from all seasons (Kharif, Rabi, Zaid)"}
- DO NOT recommend pot/garden plants like tulsi, mint, ornamental flowers etc. Those belong in PLANTS section.
- Rate each crop: Excellent (best match for this soil), Good (grows well), Moderate (will produce)
- All benefits/drawbacks from FARMER perspective (profit, investment, labor, water, MSP, government support)
- Give as many crops as possible, minimum 20

Respond with ONLY a valid JSON array:
[
  {{
    "crop_name": "English Name",
    "crop_name_hindi": "Hindi Name (हिंदी नाम)",
    "suitability": "Excellent / Good / Moderate",
    "season": "Kharif / Rabi / Zaid / All Season",
    "best_planting_month": "June-July",
    "growth_duration_days": 120,
    "crop_age_stages": "Germination: 0-10 days, Tillering: 10-35 days, Vegetative: 35-70 days, Flowering: 70-90 days, Maturity: 90-120 days",
    "seed_quantity": "40-50 kg per acre",
    "soil_preparation_steps": ["Step 1", "Step 2", "Step 3"],
    "fertilizer_schedule": "Fertilizer dosage schedule",
    "irrigation_schedule": "Irrigation frequency and timing",
    "pesticide_needs": "Common pests and pesticides with dosage",
    "weed_management": "Herbicide names and timing",
    "expected_yield": "Expected yield per acre",
    "expected_profit": "Expected profit per acre",
    "benefits": ["Benefit 1", "Benefit 2"],
    "drawbacks": ["Drawback 1", "Drawback 2"],
    "growth_requirements": ["Requirement 1", "Requirement 2", "Requirement 3"],
    "harvest_method": "How to harvest and when ready",
    "market_demand": "Market demand and MSP if applicable",
    "description": "3-4 line description about why this crop is best for the farmer"
  }}
]

All data for INDIAN farming. REALISTIC yield/profit. Specific product names and dosages. ONLY JSON array."""

    result = call_groq_json_array(
        prompt,
        images=image_paths,
        temperature=0.4,
        max_tokens=8192,
        timeout=120,
        tag=f"CropRecommendations[{language}]",
    )

    if isinstance(result, dict) and "error" in result:
        return result
    return {"crops": result}


# ── Helper ───────────────────────────────────────────
def _format_soil_info(soil_data):
    """Format soil data dict into readable string."""
    return f"""Soil Type: {soil_data.get('soil_type','Unknown')}
pH Level: {soil_data.get('ph_level','Unknown')}
Health: {soil_data.get('soil_health','Unknown')} ({soil_data.get('health_score',0)}%)
Moisture: {soil_data.get('moisture_level','Unknown')}
Organic Matter: {soil_data.get('organic_matter','Unknown')}
Nitrogen: {soil_data.get('nitrogen_level','Unknown')}
Phosphorus: {soil_data.get('phosphorus_level','Unknown')}
Potassium: {soil_data.get('potassium_level','Unknown')}"""
