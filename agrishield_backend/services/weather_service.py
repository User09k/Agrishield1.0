import requests
import random
from datetime import datetime, timedelta

def get_recent_weather(lat, lon, language: str = "en"):
    """
    Fetch LIVE weather data using Open-Meteo API (free, fast, no API key).
    Provides: Temperature, Humidity, Rainfall, Wind Speed, Solar Radiation.
    Falls back to cached/estimated data if API is unavailable.
    """
    try:
        # Open-Meteo — Free, real-time, no API key needed
        url = (
            f"https://api.open-meteo.com/v1/forecast?"
            f"latitude={lat}&longitude={lon}"
            f"&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,"
            f"weather_code,surface_pressure"
            f"&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,"
            f"shortwave_radiation_sum,wind_speed_10m_max"
            f"&timezone=Asia/Kolkata&forecast_days=1"
        )

        print(f"[Weather] Fetching LIVE data for lat={lat}, lon={lon} (lang={language})...")
        response = requests.get(url, timeout=10)

        if response.status_code == 200:
            data = response.json()
            current = data.get('current', {})
            daily = data.get('daily', {})

            live_temp = current.get('temperature_2m', 27.0)
            humidity = current.get('relative_humidity_2m', 55)
            rain = current.get('precipitation', 0.0)
            wind = current.get('wind_speed_10m', 2.0)
            weather_code = current.get('weather_code', 0)

            temp_max = daily.get('temperature_2m_max', [live_temp + 5])[0]
            temp_min = daily.get('temperature_2m_min', [live_temp - 5])[0]
            solar = daily.get('shortwave_radiation_sum', [5.0])[0]
            daily_rain = daily.get('precipitation_sum', [rain])[0]

            # Convert solar from MJ/m² to kWh/m² (divide by 3.6)
            solar_kwh = round(solar / 3.6, 2) if solar else 0.0

            # Weather condition from weather code
            condition = decode_weather_code(weather_code, language)

            # Smart advisory
            current_hour = datetime.now().hour
            advisory = generate_smart_advisory(live_temp, daily_rain, humidity, solar_kwh, wind, current_hour, language)

            status_text = "🛰️ लाइव उपग्रह मौसम डेटा" if language == "hi" else "🛰️ Live Weather Data"

            return {
                "temperature": round(live_temp, 1),
                "temp_max": round(temp_max, 1),
                "temp_min": round(temp_min, 1),
                "rainfall": round(daily_rain, 2),
                "humidity": int(humidity),
                "solar_radiation": solar_kwh,
                "wind_speed": round(wind, 1),
                "condition": condition,
                "status": status_text,
                "timestamp": datetime.now().strftime('%I:%M:%S %p'),
                "date": datetime.now().strftime('%d %B %Y'),
                "advisory": advisory,
                "alerts": generate_alerts(live_temp, daily_rain, humidity, wind, language),
                "crop_impact": get_crop_impact(live_temp, daily_rain, humidity, solar_kwh, language),
            }
        else:
            print(f"[Weather] API returned {response.status_code}")
            return get_fallback_weather(language)

    except Exception as e:
        print(f"[Weather] Error: {e}")
        return get_fallback_weather(language)


def decode_weather_code(code, language: str = "en"):
    """Convert WMO weather codes to readable conditions in English or Hindi."""
    is_hi = (language == "hi")
    if is_hi:
        codes = {
            0: "साफ आसमान ☀️",
            1: "मुख्यतः साफ 🌤️",
            2: "आंशिक रूप से बादल ⛅",
            3: "घने बादल ☁️",
            45: "कोहरा 🌫️",
            48: "पाला व कोहरा 🌫️❄️",
            51: "हल्की बूंदाबांदी 🌦️",
            53: "मध्यम बूंदाबांदी 🌦️",
            55: "घनी बूंदाबांदी 🌧️",
            61: "हल्की बारिश 🌧️",
            63: "मध्यम बारिश 🌧️",
            65: "भारी बारिश 🌧️🌧️",
            71: "हल्की बर्फबारी ❄️",
            73: "मध्यम बर्फबारी ❄️",
            75: "भारी बर्फबारी ❄️❄️",
            80: "बारिश की फुहारें 🌦️",
            81: "मध्यम बौछारें 🌧️",
            82: "तेज आंधी बारिश 🌧️⚡",
            95: "गरज के साथ बारिश ⛈️",
            96: "ओलावृष्टि के साथ आंधी ⛈️🧊",
            99: "भीषण तूफान ⛈️⚡",
        }
        return codes.get(code, f"मौसम कोड {code} 🌤️")
    else:
        codes = {
            0: "Clear Sky ☀️",
            1: "Mostly Clear 🌤️",
            2: "Partly Cloudy ⛅",
            3: "Overcast ☁️",
            45: "Foggy 🌫️",
            48: "Fog with Frost 🌫️❄️",
            51: "Light Drizzle 🌦️",
            53: "Moderate Drizzle 🌦️",
            55: "Dense Drizzle 🌧️",
            61: "Light Rain 🌧️",
            63: "Moderate Rain 🌧️",
            65: "Heavy Rain 🌧️🌧️",
            71: "Light Snow ❄️",
            73: "Moderate Snow ❄️",
            75: "Heavy Snow ❄️❄️",
            80: "Rain Showers 🌦️",
            81: "Moderate Showers 🌧️",
            82: "Violent Showers 🌧️⚡",
            95: "Thunderstorm ⛈️",
            96: "Thunderstorm + Hail ⛈️🧊",
            99: "Severe Thunderstorm ⛈️⚡",
        }
        return codes.get(code, f"Weather Code {code} 🌤️")


def generate_smart_advisory(temp, rain, humidity, solar, wind, hour, language: str = "en"):
    """Generate intelligent farming advisory based on weather conditions."""
    is_hi = (language == "hi")
    advisories = []

    if temp > 38:
        advisories.append("⚠️ भीषण गर्मी! सिंचाई बढ़ाएं। सुबह 11 से दोपहर 3 बजे तक धूप में काम से बचें।" if is_hi else "⚠️ Extreme heat! Increase irrigation. Avoid fieldwork 11AM-3PM.")
    elif temp > 34:
        advisories.append("🌡️ उच्च तापमान। फसल में नमी बनाए रखें। नमी संरक्षण हेतु मल्चिंग का उपयोग करें।" if is_hi else "🌡️ High temperature. Ensure crop hydration. Use mulching for soil moisture.")
    elif temp < 10:
        advisories.append("❄️ ठंड का मौसम। संवेदनशील फसलों की रक्षा करें। सुबह की सिंचाई टालें।" if is_hi else "❄️ Cold conditions. Protect sensitive crops. Delay morning irrigation.")

    if rain > 10:
        advisories.append("🌧️ भारी वर्षा की संभावना। खेतों में जल निकासी की व्यवस्था करें।" if is_hi else "🌧️ Heavy rainfall. Check drainage. Watch for waterlogging.")
    elif rain > 3:
        advisories.append("🌦️ मध्यम बारिश। सिंचाई रोकें। बारिश के बाद खाद डालने का सही समय।" if is_hi else "🌦️ Moderate rain. Reduce irrigation. Good time for post-rain fertilizer.")
    elif rain == 0 and humidity < 40:
        advisories.append("☀️ शुष्क मौसम। नियमित सिंचाई करें। मिट्टी में नमी की निगरानी रखें।" if is_hi else "☀️ Dry conditions. Schedule regular irrigation. Monitor soil moisture.")

    if humidity > 85:
        advisories.append("🍃 उच्च आर्द्रता = फंगल रोग का जोखिम। कवकनाशी का छिड़काव तैयार रखें।" if is_hi else "🍃 High humidity = disease risk. Monitor for fungal infections.")
    elif humidity < 30:
        advisories.append("💨 कम नमी। पौधों में पानी की कमी हो सकती है। सिंचाई बढ़ाएं।" if is_hi else "💨 Low humidity. Crops may face water stress. Increase watering.")

    if wind > 20:
        advisories.append("🌬️ तेज हवा! कीटनाशक छिड़काव से बचें। पौधों को सहारा दें।" if is_hi else "🌬️ Strong winds! Avoid spraying. Secure young plants.")

    if not advisories:
        advisories.append("✅ मौसम खेती के लिए अनुकूल है। सामान्य कृषि कार्य जारी रख सकते हैं।" if is_hi else "✅ Weather is favorable for farming. Normal activities can continue.")

    return " | ".join(advisories)


def generate_alerts(temp, rain, humidity, wind, language: str = "en"):
    """Generate weather alert list in requested language."""
    is_hi = (language == "hi")
    alerts = []
    if temp > 38:
        alerts.append({"type": "danger", "message": "लू / भीषण गर्मी की चेतावनी" if is_hi else "Heat Wave Warning"})
    elif temp > 34:
        alerts.append({"type": "warning", "message": "उच्च तापमान चेतावनी" if is_hi else "High Temperature Alert"})
    if rain > 10:
        alerts.append({"type": "danger", "message": "भारी वर्षा की चेतावनी" if is_hi else "Heavy Rainfall Alert"})
    if humidity > 85:
        alerts.append({"type": "warning", "message": "उच्च आर्द्रता - रोग का खतरा" if is_hi else "High Humidity - Disease Risk"})
    if wind > 20:
        alerts.append({"type": "warning", "message": "तेज हवा की सलाह" if is_hi else "Strong Wind Advisory"})
    if temp < 5:
        alerts.append({"type": "danger", "message": "पाला पड़ने की चेतावनी" if is_hi else "Frost Warning"})
    if not alerts:
        alerts.append({"type": "safe", "message": "कोई मौसम चेतावनी नहीं" if is_hi else "No weather alerts"})
    return alerts


def get_crop_impact(temp, rain, humidity, solar, language: str = "en"):
    """Assess how weather affects crops in requested language."""
    is_hi = (language == "hi")
    if 20 <= temp <= 30 and rain > 0 and 50 <= humidity <= 75:
        growth = "उत्कृष्ट (Optimal)" if is_hi else "Optimal"
    elif 15 <= temp <= 35 and humidity >= 40:
        growth = "अच्छा (Good)" if is_hi else "Good"
    elif temp > 38 or temp < 10:
        growth = "तनावग्रस्त (Stressed)" if is_hi else "Stressed"
    else:
        growth = "सामान्य (Moderate)" if is_hi else "Moderate"

    if humidity > 80 and rain > 2:
        disease_risk = "अधिक (High)" if is_hi else "High"
    elif humidity > 70:
        disease_risk = "मध्यम (Moderate)" if is_hi else "Moderate"
    else:
        disease_risk = "कम (Low)" if is_hi else "Low"

    if rain > 5:
        irrigation = "आवश्यकता नहीं (Not Needed)" if is_hi else "Not Needed"
    elif rain > 1:
        irrigation = "कम सिंचाई (Reduced)" if is_hi else "Reduced"
    elif temp > 32:
        irrigation = "प्राथमिकता पर सिंचाई (High Priority)" if is_hi else "High Priority"
    else:
        irrigation = "सामान्य कार्यक्रम (Normal Schedule)" if is_hi else "Normal Schedule"

    return {
        "growth_speed": growth,
        "disease_risk": disease_risk,
        "irrigation_need": irrigation,
    }


def get_fallback_weather(language: str = "en"):
    """Fallback when API unavailable."""
    is_hi = (language == "hi")
    hour = datetime.now().hour
    base = 26 if 6 <= hour <= 18 else 22
    return {
        "temperature": round(base + random.uniform(-1, 2), 1),
        "temp_max": base + 6,
        "temp_min": base - 4,
        "rainfall": 0.0,
        "humidity": 55,
        "solar_radiation": 5.0 if 6 <= hour <= 18 else 0.0,
        "wind_speed": 2.0,
        "condition": "डेटा सिंक लंबित 🔄" if is_hi else "Data Sync Pending 🔄",
        "status": "⚡ ऑफ़लाइन मोड" if is_hi else "⚡ Offline Mode",
        "timestamp": datetime.now().strftime('%I:%M:%S %p'),
        "date": datetime.now().strftime('%d %B %Y'),
        "advisory": "📡 मौसम डेटा सिंक हो रहा है। अनुमानित डेटा प्रदर्शित।" if is_hi else "📡 Weather sync in progress. Showing estimated data.",
        "alerts": [{"type": "info", "message": "कैश किया गया डेटा उपयोग हो रहा है" if is_hi else "Using cached data"}],
        "crop_impact": {
            "growth_speed": "सामान्य (Normal)" if is_hi else "Normal",
            "disease_risk": "कम (Low)" if is_hi else "Low",
            "irrigation_need": "सामान्य कार्यक्रम" if is_hi else "Normal Schedule"
        },
    }


# =====================================================
# 48-HOUR SMART SPRAY WINDOW ADVISOR
# =====================================================
def get_spray_advisory(lat: float, lon: float, language: str = "en") -> dict:
    """
    48-Hour Smart Spray Window Advisor with full bilingual support.
    Calculates exact hourly safe, moderate, and risky windows for pesticide/fertilizer spraying.
    """
    is_hi = (language == "hi")
    try:
        url = (
            f"https://api.open-meteo.com/v1/forecast?"
            f"latitude={lat}&longitude={lon}"
            f"&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,precipitation,wind_speed_10m,weather_code"
            f"&timezone=Asia/Kolkata&forecast_days=2"
        )
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return _get_fallback_spray_advisory()

        data = response.json()
        hourly = data.get("hourly", {})
        times = hourly.get("time", [])
        temps = hourly.get("temperature_2m", [])
        humidities = hourly.get("relative_humidity_2m", [])
        rain_probs = hourly.get("precipitation_probability", [])
        precips = hourly.get("precipitation", [])
        winds = hourly.get("wind_speed_10m", [])
        codes = hourly.get("weather_code", [])

        now_str = datetime.now().strftime("%Y-%m-%dT%H:00")

        timeline = []
        safe_windows = []
        current_safe_streak = []

        start_idx = 0
        for i, t in enumerate(times):
            if t >= now_str:
                start_idx = i
                break

        for i in range(start_idx, min(start_idx + 24, len(times))):
            t_raw = times[i]
            temp = temps[i] if i < len(temps) else 25.0
            hum = humidities[i] if i < len(humidities) else 50
            rain_prob = rain_probs[i] if i < len(rain_probs) else 0
            precip = precips[i] if i < len(precips) else 0.0
            wind = winds[i] if i < len(winds) else 5.0

            dt = datetime.fromisoformat(t_raw)
            hour_label = dt.strftime("%I:%M %p")
            day_label = "Today" if dt.date() == datetime.now().date() else "Tomorrow"
            day_label_hi = "आज" if dt.date() == datetime.now().date() else "कल"

            status = "SAFE"
            status_text = "छिड़काव के लिए सर्वोत्तम समय (Safe)" if is_hi else "Optimal for Spraying"
            status_en = "Optimal Window"
            color = "#2E7D32"
            icon = "🟢"
            reason = "शांत हवा, बारिश की शून्य संभावना। 100% दवा का असर मिलेगा।" if is_hi else "Calm wind, zero rain probability. 100% spray efficiency expected."

            if precip > 0.1 or rain_prob >= 35:
                status = "DANGER"
                status_text = "बारिश का खतरा — छिड़काव न करें" if is_hi else "High Rain Risk — Do Not Spray"
                status_en = "High Rain Risk"
                color = "#D32F2F"
                icon = "🌧️"
                reason = f"बारिश की संभावना {rain_prob}% है। दवा धुल जाएगी।" if is_hi else f"Rain probability is {rain_prob}%. Chemical will wash off into the soil."
            elif wind > 16.0:
                status = "DANGER"
                status_text = "तेज हवा — छिड़काव टालें" if is_hi else "High Wind Drift — Avoid Spray"
                status_en = "High Wind Drift"
                color = "#D32F2F"
                icon = "💨"
                reason = f"हवा की गति {round(wind, 1)} km/h अधिक है। दवा उड़ने का खतरा।" if is_hi else f"Wind speed of {round(wind, 1)} km/h is too high. Severe drift loss hazard."
            elif temp > 35.0:
                status = "DANGER"
                status_text = "अत्यधिक गर्मी — छिड़काव न करें" if is_hi else "Extreme Heat — Avoid Spray"
                status_en = "Extreme Heat"
                color = "#D32F2F"
                icon = "☀️"
                reason = f"अधिक तापमान ({round(temp, 1)}°C) से दवा वाष्पित होगी और पत्तियां झुलस सकती हैं।" if is_hi else f"High temperature ({round(temp, 1)}°C) causes droplet evaporation and leaf scorch."
            elif temp < 12.0:
                status = "CAUTION"
                status_text = "कम तापमान — दवा देरी से असर करेगी" if is_hi else "Cold Temperature — Delayed Effect"
                status_en = "Cold Temperature"
                color = "#F57C00"
                icon = "❄️"
                reason = "ठंडे मौसम में पौधों के रंध्र बंद रहते हैं; दवा धीमी गति से काम करेगी।" if is_hi else "Plant stomata are closed in cold weather; chemical absorption is delayed."
            elif wind >= 12.0 or rain_prob >= 20 or hum > 85:
                status = "CAUTION"
                status_text = "मध्यम स्थिति — चिपको (Sticker) मिलाकर छिड़कें" if is_hi else "Moderate Window — Use Sticker"
                status_en = "Moderate Window"
                color = "#F57C00"
                icon = "🟡"
                reason = f"हवा {round(wind, 1)} km/h या आर्द्रता {hum}% है। सिलिकॉन चिपको स्टीकर अवश्य मिलाएं।" if is_hi else f"Wind {round(wind, 1)} km/h or humidity {hum}%. Add a silicone sticker before spraying."

            is_daylight = (6 <= dt.hour <= 18)
            if status == "SAFE" and is_daylight:
                current_safe_streak.append(dt)
            else:
                if len(current_safe_streak) >= 2:
                    safe_windows.append((current_safe_streak[0], current_safe_streak[-1]))
                current_safe_streak = []

            timeline.append({
                "time_iso": t_raw,
                "hour_label": hour_label,
                "day_label": day_label_hi if is_hi else day_label,
                "day_label_hi": day_label_hi,
                "status": status,
                "status_text": status_text,
                "status_en": status_en,
                "color": color,
                "icon": icon,
                "reason": reason,
                "temperature": round(temp, 1),
                "humidity": int(hum),
                "rain_prob": int(rain_prob),
                "wind_speed": round(wind, 1),
            })

        if len(current_safe_streak) >= 2:
            safe_windows.append((current_safe_streak[0], current_safe_streak[-1]))

        current_status = timeline[0] if timeline else {
            "status": "SAFE",
            "status_text": "छिड़काव के लिए अनुकूल" if is_hi else "Optimal for Spraying",
            "color": "#2E7D32",
            "icon": "🟢",
            "reason": "सामान्य मौसम।" if is_hi else "Normal weather conditions."
        }

        if safe_windows:
            start_dt, end_dt = safe_windows[0]
            day_prefix = ("आज" if start_dt.date() == datetime.now().date() else "कल") if is_hi else ("Today" if start_dt.date() == datetime.now().date() else "Tomorrow")
            next_window_title = f"{day_prefix} {start_dt.strftime('%I:%M %p')} से {end_dt.strftime('%I:%M %p')}" if is_hi else f"{day_prefix} {start_dt.strftime('%I:%M %p')} to {end_dt.strftime('%I:%M %p')}"
            next_window_desc = "लगातार सुरक्षित समय। हल्की हवा और बारिश की शून्य संभावना।" if is_hi else "Continuous safe window. Low wind speed and zero rain probability."
            next_window_badge = "🟢 अनुकूल समय" if is_hi else "🟢 Optimal Window"
        else:
            next_window_title = "अगले 24 घंटों में कोई लंबा सुरक्षित समय नहीं" if is_hi else "No extended safe window in next 24h"
            next_window_desc = "बारिश या तेज हवा की संभावना। केवल अति आवश्यक होने पर सुबह स्टीकर मिलाकर ही छिड़कें।" if is_hi else "Rain or high winds expected. Spray early morning with a sticker only if urgent."
            next_window_badge = "⚠️ सावधानी आवश्यक" if is_hi else "⚠️ Caution Needed"

        if is_hi:
            guidelines = [
                {"title": "सिलिकॉन स्प्रेडर (चिपको) का उपयोग करें", "desc": "1 मिली/लीटर सिलिकॉन स्टीकर मिलाएं ताकि दवा पत्तों पर मजबूती से चिपके और बारिश में न धुले।", "icon": "🧴"},
                {"title": "हवा की दिशा में ही स्प्रे करें", "desc": "हमेशा हवा के बहाव की दिशा में आगे बढ़ें, कभी भी हवा के सामने न चलें।", "icon": "🌬️"},
                {"title": "दोपहर की कड़ी धूप में स्प्रे न करें", "desc": "सुबह 7-10 बजे या शाम 4-6 बजे छिड़काव करें ताकि दवा वाष्पित न हो और पत्तियां न झुलसें।", "icon": "☀️"},
                {"title": "सुरक्षा किट (मास्क व दस्ताने) पहनें", "desc": "कीटनाशक छिड़कते समय चेहरे पर मास्क, चश्मा और रबर के दस्ताने अवश्य पहनें।", "icon": "😷"},
            ]
        else:
            guidelines = [
                {"title": "Use Silicone Spreader Sticker", "desc": "Mix 1ml/L silicone adjuvant so spray sticks firmly to foliage without wash-off.", "icon": "🧴"},
                {"title": "Spray in Wind Direction", "desc": "Always spray moving in the direction of the wind; never walk against the wind.", "icon": "🌬️"},
                {"title": "Avoid Midday Peak Sun", "desc": "Spray between 7-10 AM or 4-6 PM to avoid intense evaporation and leaf scorch.", "icon": "☀️"},
                {"title": "Wear Personal Protective Gear", "desc": "Always wear a protective mask, eye goggles, and rubber gloves while spraying.", "icon": "😷"},
            ]

        return {
            "success": True,
            "current_status": current_status,
            "next_best_window": {
                "title": next_window_title,
                "description": next_window_desc,
                "badge": next_window_badge,
                "hourly_timeline": timeline[:24],
            },
            "hourly_timeline": timeline[:24],
            "timeline": timeline[:24],
            "guidelines": guidelines,
            "timestamp": datetime.now().strftime("%I:%M %p"),
        }
    except Exception as e:
        print(f"[SprayAdvisor] Error: {e}")
        return _get_fallback_spray_advisory()


def _get_fallback_spray_advisory():
    """Offline/fallback mock spray window advisory."""
    return {
        "success": True,
        "current_status": {
            "status": "SAFE",
            "status_text": "छिड़काव के लिए उत्तम",
            "color": "#2E7D32",
            "icon": "🟢",
            "reason": "शांत हवा, बारिश का कोई खतरा नहीं। दवा का पूरा असर होगा।"
        },
        "next_best_window": {
            "title": "कल सुबह 07:00 AM से 10:30 AM",
            "description": "3.5 घंटे का सुरक्षित समय। हवा 5 km/h और बारिश 0% अनुमानित है।",
            "badge": "🟢 सर्वोत्तम समय (Optimal)"
        },
        "timeline": [
            {"hour_label": "07:00 AM", "day_label_hi": "कल", "status": "SAFE", "status_text": "उत्तम समय", "color": "#2E7D32", "icon": "🟢", "wind_speed": 4.5, "rain_prob": 5, "temperature": 24},
            {"hour_label": "09:00 AM", "day_label_hi": "कल", "status": "SAFE", "status_text": "उत्तम समय", "color": "#2E7D32", "icon": "🟢", "wind_speed": 6.2, "rain_prob": 5, "temperature": 27},
            {"hour_label": "01:00 PM", "day_label_hi": "कल", "status": "DANGER", "status_text": "अधिक गर्मी", "color": "#D32F2F", "icon": "☀️", "wind_speed": 11.0, "rain_prob": 10, "temperature": 34},
            {"hour_label": "04:00 PM", "day_label_hi": "कल", "status": "SAFE", "status_text": "शाम का समय", "color": "#2E7D32", "icon": "🟢", "wind_speed": 7.0, "rain_prob": 5, "temperature": 29},
        ],
        "guidelines": [
            {"title": "चिपको (Sticker) का प्रयोग", "desc": "दवा के साथ 1ml/लीटर सिलिकॉन स्प्रेडर जरूर मिलाएं।", "icon": "🧴"},
            {"title": "हवा की दिशा का ध्यान", "desc": "हमेशा हवा की दिशा में ही स्प्रे करें।", "icon": "🌬️"},
        ],
        "timestamp": datetime.now().strftime("%I:%M %p"),
    }