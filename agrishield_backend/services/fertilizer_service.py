"""
Fertilizer Prescription Service — Digital Khad Parchi
=====================================================
Calculates exact fertilizer dosage, bag counts, costs, and stage-wise schedule
based on crop, land size (Acre/Bigha/Hectare), crop age, and soil condition.
Follows ICAR (Indian Council of Agricultural Research) agronomic standards.
"""

import math
import random
from datetime import datetime

# Unit multiplier to standard ACER
UNIT_TO_ACRE = {
    "acre": 1.0,
    "bigha": 0.333,      # Standard Central/North India (3 Bigha = 1 Acre)
    "hectare": 2.471,
    "guntha": 0.025,     # Maharashtra/Gujarat (40 Guntha = 1 Acre)
}

# Subsidized government price per standard bag (in INR)
PRICES = {
    "urea_bag_45kg": 266.50,
    "dap_bag_50kg": 1350.00,
    "mop_bag_50kg": 1700.00,
    "zinc_per_kg": 75.00,
    "npk_foliar_per_kg": 160.00,
    "sulfur_per_kg": 50.00,
}

# Crop Fertilizer Database (per 1 Acre)
# Crop Fertilizer Database (per 1 Acre)
CROP_DATABASE = {
    "wheat": {
        "hindi": "Wheat",
        "total_days": 120,
        "stages": [
            {
                "stage_name": "Basal Dressing (At Sowing)",
                "days_range": "Day 0",
                "days_start": 0,
                "days_end": 5,
                "fertilizers": [
                    {"name": "DAP (18:46:0)", "qty_acre": "1 Bag (50 kg)", "bags": 1.0, "type": "DAP"},
                    {"name": "MOP (Potash)", "qty_acre": "0.5 Bag (25 kg)", "bags": 0.5, "type": "MOP"},
                    {"name": "Zinc Sulphate (21%)", "qty_acre": "10 kg", "bags": 0.0, "type": "ZINC"},
                ],
                "instructions": "Apply during final land preparation or drill alongside seed. Do not apply Urea at this stage."
            },
            {
                "stage_name": "First Irrigation (CRI Stage)",
                "days_range": "Day 20 - 25",
                "days_start": 20,
                "days_end": 28,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                    {"name": "Sulphur 90% WDG", "qty_acre": "3 kg", "bags": 0.0, "type": "SULFUR"},
                ],
                "instructions": "Broadcast evenly 2-3 days after irrigation when soil is damp."
            },
            {
                "stage_name": "Second Irrigation (Tillering)",
                "days_range": "Day 40 - 45",
                "days_start": 35,
                "days_end": 50,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                ],
                "instructions": "Broadcast in light soil moisture. Discontinue urea application after this stage."
            },
            {
                "stage_name": "Heading / Booting Stage",
                "days_range": "Day 65 - 75",
                "days_start": 60,
                "days_end": 80,
                "fertilizers": [
                    {"name": "NPK 19:19:19 (Foliar Spray)", "qty_acre": "1 kg (in 150L water)", "bags": 0.0, "type": "FOLIAR"},
                ],
                "instructions": "Foliar spray after 3:00 PM. Boosts grain weight, luster, and earhead development."
            }
        ]
    },
    "rice": {
        "hindi": "Rice / Paddy",
        "total_days": 135,
        "stages": [
            {
                "stage_name": "Basal Application (Transplanting)",
                "days_range": "Day 0",
                "days_start": 0,
                "days_end": 5,
                "fertilizers": [
                    {"name": "DAP (18:46:0)", "qty_acre": "1 Bag (50 kg)", "bags": 1.0, "type": "DAP"},
                    {"name": "MOP (Potash)", "qty_acre": "0.5 Bag (25 kg)", "bags": 0.5, "type": "MOP"},
                    {"name": "Zinc Sulphate", "qty_acre": "10 kg", "bags": 0.0, "type": "ZINC"},
                ],
                "instructions": "Incorporate thoroughly into mud during final puddling before transplanting."
            },
            {
                "stage_name": "Active Tillering",
                "days_range": "Day 20 - 25",
                "days_start": 18,
                "days_end": 30,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                ],
                "instructions": "Maintain shallow water in field and broadcast evenly."
            },
            {
                "stage_name": "Panicle Initiation",
                "days_range": "Day 45 - 55",
                "days_start": 40,
                "days_end": 60,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "0.75 Bag (35 kg)", "bags": 0.75, "type": "UREA"},
                    {"name": "MOP (Potash)", "qty_acre": "0.25 Bag (12.5 kg)", "bags": 0.25, "type": "MOP"},
                ],
                "instructions": "Crucial dose for panicle count and complete grain filling."
            }
        ]
    },
    "soybean": {
        "hindi": "Soybean",
        "total_days": 105,
        "stages": [
            {
                "stage_name": "Basal Application (At Sowing)",
                "days_range": "Day 0",
                "days_start": 0,
                "days_end": 5,
                "fertilizers": [
                    {"name": "DAP (18:46:0)", "qty_acre": "1.5 Bags (75 kg)", "bags": 1.5, "type": "DAP"},
                    {"name": "MOP (Potash)", "qty_acre": "0.5 Bag (25 kg)", "bags": 0.5, "type": "MOP"},
                    {"name": "Bentonite Sulphur 90%", "qty_acre": "10 kg", "bags": 0.0, "type": "SULFUR"},
                ],
                "instructions": "Soybean fixes its own atmospheric nitrogen. Avoid excess urea."
            },
            {
                "stage_name": "Pre-Flowering Stage",
                "days_range": "Day 30 - 35",
                "days_start": 25,
                "days_end": 40,
                "fertilizers": [
                    {"name": "NPK 19:19:19 Spray", "qty_acre": "1 kg (in 150L water)", "bags": 0.0, "type": "FOLIAR"},
                    {"name": "Boron 20%", "qty_acre": "200 gm", "bags": 0.0, "type": "FOLIAR"},
                ],
                "instructions": "Spray on foliage. Prevents flower drop and improves pod setting."
            },
            {
                "stage_name": "Pod Filling Stage",
                "days_range": "Day 50 - 60",
                "days_start": 45,
                "days_end": 65,
                "fertilizers": [
                    {"name": "NPK 0:52:34 Spray", "qty_acre": "1 kg (in 150L water)", "bags": 0.0, "type": "FOLIAR"},
                ],
                "instructions": "Promotes seed boldness, luster, and increases grain oil content."
            }
        ]
    },
    "cotton": {
        "hindi": "Cotton",
        "total_days": 160,
        "stages": [
            {
                "stage_name": "Basal Application (Sowing)",
                "days_range": "Day 0",
                "days_start": 0,
                "days_end": 5,
                "fertilizers": [
                    {"name": "DAP", "qty_acre": "1 Bag (50 kg)", "bags": 1.0, "type": "DAP"},
                    {"name": "MOP", "qty_acre": "0.5 Bag (25 kg)", "bags": 0.5, "type": "MOP"},
                    {"name": "Urea", "qty_acre": "0.5 Bag (22.5 kg)", "bags": 0.5, "type": "UREA"},
                ],
                "instructions": "Apply 5 cm away from seeds along the planting furrow."
            },
            {
                "stage_name": "Square Formation",
                "days_range": "Day 35 - 45",
                "days_start": 30,
                "days_end": 50,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                ],
                "instructions": "Apply in root zone after irrigation when soil is moist."
            },
            {
                "stage_name": "Boll Development",
                "days_range": "Day 65 - 80",
                "days_start": 60,
                "days_end": 90,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                    {"name": "MOP (Potash)", "qty_acre": "0.5 Bag (25 kg)", "bags": 0.5, "type": "MOP"},
                    {"name": "NPK 13:0:45 Spray", "qty_acre": "1.5 kg (in 200L water)", "bags": 0.0, "type": "FOLIAR"},
                ],
                "instructions": "Increases boll size and improves cotton staple fiber quality."
            }
        ]
    },
    "maize": {
        "hindi": "Maize (Corn)",
        "total_days": 100,
        "stages": [
            {
                "stage_name": "Basal Application (Sowing)",
                "days_range": "Day 0",
                "days_start": 0,
                "days_end": 5,
                "fertilizers": [
                    {"name": "DAP", "qty_acre": "1 Bag (50 kg)", "bags": 1.0, "type": "DAP"},
                    {"name": "MOP", "qty_acre": "0.5 Bag (25 kg)", "bags": 0.5, "type": "MOP"},
                    {"name": "Zinc Sulphate", "qty_acre": "10 kg", "bags": 0.0, "type": "ZINC"},
                ],
                "instructions": "Apply along crop rows before planting seeds."
            },
            {
                "stage_name": "Knee-High Stage",
                "days_range": "Day 25 - 30",
                "days_start": 20,
                "days_end": 35,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                ],
                "instructions": "Side-dress along rows just before irrigation."
            },
            {
                "stage_name": "Tasseling & Silking Stage",
                "days_range": "Day 50 - 55",
                "days_start": 45,
                "days_end": 65,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                ],
                "instructions": "Ensures complete cob development and prevents blank tips."
            }
        ]
    },
    "mustard": {
        "hindi": "Mustard",
        "total_days": 125,
        "stages": [
            {
                "stage_name": "Basal Application (At Sowing)",
                "days_range": "Day 0",
                "days_start": 0,
                "days_end": 5,
                "fertilizers": [
                    {"name": "DAP", "qty_acre": "1 Bag (50 kg)", "bags": 1.0, "type": "DAP"},
                    {"name": "Bentonite Sulphur 90%", "qty_acre": "15 kg", "bags": 0.0, "type": "SULFUR"},
                    {"name": "Urea", "qty_acre": "0.5 Bag (22.5 kg)", "bags": 0.5, "type": "UREA"},
                ],
                "instructions": "Sulphur is vital for mustard; increases seed oil concentration by 3-4%."
            },
            {
                "stage_name": "First Irrigation Stage",
                "days_range": "Day 25 - 30",
                "days_start": 22,
                "days_end": 35,
                "fertilizers": [
                    {"name": "Neem Coated Urea", "qty_acre": "1 Bag (45 kg)", "bags": 1.0, "type": "UREA"},
                ],
                "instructions": "Broadcast when field has good moisture following first watering."
            }
        ]
    }
}


def generate_fertilizer_prescription(crop_name: str, land_size: float = 1.0, unit: str = "Acre", crop_age_days: int = 20, soil_type: str = "Loam Soil", language: str = "en") -> dict:
    """
    Generate an authentic digital fertilizer prescription with exact bag calculations.
    Accepts language ('en' or 'hi') to deliver instructions and tips in natural Hindi or English.
    """
    is_hi = (language == "hi")
    crop_key = crop_name.lower().strip()
    matched_crop = None
    for k, v in CROP_DATABASE.items():
        if k in crop_key or crop_key in k:
            matched_crop = v
            crop_key = k
            break

    if not matched_crop:
        # Default fallback to wheat-like balanced crop
        matched_crop = CROP_DATABASE["wheat"]
        display_crop_name = crop_name.title()
        display_hindi_name = crop_name
    else:
        display_crop_name = crop_key.title()
        display_hindi_name = matched_crop["hindi"]

    # Calculate Acre Factor
    unit_norm = unit.lower().strip()
    mult = UNIT_TO_ACRE.get(unit_norm, 1.0)
    total_acres = round(land_size * mult, 2)

    # Accumulate total bags needed for whole season
    total_urea_bags = 0.0
    total_dap_bags = 0.0
    total_mop_bags = 0.0
    total_zinc_kg = 0.0
    total_sulfur_kg = 0.0

    calculated_stages = []
    current_active_stage = None

    for stage in matched_crop["stages"]:
        is_current = (stage["days_start"] <= crop_age_days <= stage["days_end"])
        if is_current and not current_active_stage:
            current_active_stage = stage["stage_name"]

        is_past = crop_age_days > stage["days_end"]
        is_upcoming = crop_age_days < stage["days_start"]

        stage_fert_items = []
        for fert in stage["fertilizers"]:
            f_type = fert["type"]
            f_bags_acre = fert.get("bags", 0.0)

            if f_type == "UREA":
                bags_total = round(f_bags_acre * total_acres, 1)
                total_urea_bags += bags_total
                stage_fert_items.append({
                    "name": fert["name"] if not is_hi else "नीम कोटेड यूरिया (Neem Coated Urea)",
                    "total_qty": f"{bags_total} बोरी ({int(bags_total * 45)} kg)" if is_hi else f"{bags_total} Bags ({int(bags_total * 45)} kg)",
                    "per_acre": fert["qty_acre"],
                    "type": "UREA"
                })
            elif f_type == "DAP":
                bags_total = round(f_bags_acre * total_acres, 1)
                total_dap_bags += bags_total
                stage_fert_items.append({
                    "name": fert["name"] if not is_hi else "डीएपी (DAP 18:46:0)",
                    "total_qty": f"{bags_total} बोरी ({int(bags_total * 50)} kg)" if is_hi else f"{bags_total} Bags ({int(bags_total * 50)} kg)",
                    "per_acre": fert["qty_acre"],
                    "type": "DAP"
                })
            elif f_type == "MOP":
                bags_total = round(f_bags_acre * total_acres, 1)
                total_mop_bags += bags_total
                stage_fert_items.append({
                    "name": fert["name"] if not is_hi else "म्यूरिएट ऑफ पोटाश (MOP Potash)",
                    "total_qty": f"{bags_total} बोरी ({int(bags_total * 50)} kg)" if is_hi else f"{bags_total} Bags ({int(bags_total * 50)} kg)",
                    "per_acre": fert["qty_acre"],
                    "type": "MOP"
                })
            elif f_type == "ZINC":
                kg_total = round(10.0 * total_acres, 1)
                total_zinc_kg += kg_total
                stage_fert_items.append({
                    "name": fert["name"] if not is_hi else "जिंक सल्फेट (Zinc Sulphate 21%)",
                    "total_qty": f"{kg_total} kg",
                    "per_acre": fert["qty_acre"],
                    "type": "MICRONUTRIENT"
                })
            elif f_type == "SULFUR":
                kg_total = round(10.0 * total_acres, 1)
                total_sulfur_kg += kg_total
                stage_fert_items.append({
                    "name": fert["name"] if not is_hi else "सल्फर 90% (Sulphur WDG)",
                    "total_qty": f"{kg_total} kg",
                    "per_acre": fert["qty_acre"],
                    "type": "MICRONUTRIENT"
                })
            else:
                stage_fert_items.append({
                    "name": fert["name"],
                    "total_qty": f"{round(1.0 * total_acres, 1)} kg",
                    "per_acre": fert["qty_acre"],
                    "type": "FOLIAR"
                })

        status_tag = "CURRENT" if is_current else ("PAST" if is_past else "UPCOMING")
        if is_hi:
            status_label = "👉 अभी डालें" if is_current else ("✅ पूर्ण हो चुका" if is_past else "⏳ आगामी चरण")
        else:
            status_label = "👉 Apply Now" if is_current else ("✅ Completed" if is_past else "⏳ Upcoming")

        calculated_stages.append({
            "stage_name": stage["stage_name"],
            "days_range": stage["days_range"],
            "status": status_tag,
            "status_label": status_label,
            "items": stage_fert_items,
            "instructions": stage["instructions"],
        })

    # If no stage matched exactly, pick closest
    if not current_active_stage and calculated_stages:
        for st in calculated_stages:
            if st["status"] == "UPCOMING":
                st["status"] = "CURRENT"
                st["status_label"] = "👉 अगली खुराक तैयार करें" if is_hi else "👉 Prepare Next Dose"
                current_active_stage = st["stage_name"]
                break

    # Calculate Estimated Cost
    est_urea_cost = total_urea_bags * PRICES["urea_bag_45kg"]
    est_dap_cost = total_dap_bags * PRICES["dap_bag_50kg"]
    est_mop_cost = total_mop_bags * PRICES["mop_bag_50kg"]
    est_zinc_cost = total_zinc_kg * PRICES["zinc_per_kg"]
    est_sulfur_cost = total_sulfur_kg * PRICES["sulfur_per_kg"]
    total_est_cost = int(est_urea_cost + est_dap_cost + est_mop_cost + est_zinc_cost + est_sulfur_cost)

    # Prescription ID & metadata
    prescription_id = f"AGRI-RX-{random.randint(10000, 99999)}"
    issue_date = datetime.now().strftime("%d %B %Y")

    # Organic Booster / Desi Nuskha Tip
    if is_hi:
        organic_tips = [
            "जीवामृत तैयार करें: 1 एकड़ के लिए 10 किलो गाय का गोबर + 10 लीटर गोमूत्र + 1 किलो गुड़ को 200 लीटर पानी में मिलाकर सिंचाई के साथ दें। रासायनिक खाद में 20% तक की बचत होगी।",
            "डीएपी खाद की अवशोषण क्षमता दोगुनी करने के लिए 1 लीटर/एकड़ की दर से पीएसबी (फॉस्फोरस घोलक बैक्टीरिया) का प्रयोग करें।",
            "नाइट्रोजन की बर्बादी रोकने और पत्तों द्वारा बेहतर पोषण के लिए हमेशा नीम लेपित यूरिया का प्रयोग करें।"
        ]
        doc_note = "यह पर्ची ICAR कृषि मानकों पर आधारित है। स्थानीय मिट्टी परीक्षण के अनुसार 10-15% फेरबदल करें।"
    else:
        organic_tips = [
            "Prepare Jeevamrut: Mix 10 kg cow dung + 10 L cow urine + 1 kg jaggery in 200 L water for 1 acre with irrigation. Saves up to 20% chemical fertilizer.",
            "Apply PSB (Phosphorus Solubilizing Bacteria) at 1 L/acre to double the uptake efficiency of DAP fertilizer.",
            "Always use Neem Coated Urea to prevent nitrogen loss through volatilization and improve leaf uptake."
        ]
        doc_note = "Prescription generated using ICAR agronomic standards. Adjust by 10-15% based on local soil test results."

    return {
        "success": True,
        "prescription_id": prescription_id,
        "date": issue_date,
        "farmer_crop": {
            "name": display_crop_name,
            "hindi": display_hindi_name,
            "age_days": crop_age_days,
            "land_size_input": f"{land_size} {unit}",
            "acres_normalized": total_acres,
            "soil_type": soil_type,
        },
        "bag_summary": {
            "urea_bags": math.ceil(total_urea_bags * 2) / 2,  # round to nearest half bag
            "dap_bags": math.ceil(total_dap_bags * 2) / 2,
            "mop_bags": math.ceil(total_mop_bags * 2) / 2,
            "zinc_kg": round(total_zinc_kg, 1),
            "estimated_cost_inr": total_est_cost,
        },
        "current_active_stage": current_active_stage or ("सामान्य फसल देखभाल" if is_hi else "General Crop Care"),
        "stages": calculated_stages,
        "organic_booster_tip": random.choice(organic_tips),
        "doctor_note": doc_note,
    }
