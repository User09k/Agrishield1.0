from flask import Flask, request, jsonify, g
from flask_cors import CORS
import os
import sys
import json
import time
import uuid
import logging
from datetime import datetime
import socket
from dotenv import load_dotenv

# Fix Windows terminal encoding for emoji output
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

# Add parent directory (workspace root) to path so we can import agrishield_twilio
_backend_dir = os.path.dirname(os.path.abspath(__file__))
_root_dir = os.path.abspath(os.path.join(_backend_dir, '..'))
for _p in [_backend_dir, _root_dir]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

# Import services
from services.groq_crop_analysis import analyze_crop_with_groq
from services.weather_service import get_recent_weather, get_spray_advisory
from services.market_service import get_market_prices
from services.groq_soil_analysis import analyze_soil_image, get_plant_recommendations, get_crop_recommendations
from services.groq_agri_services import get_recovery_advice, calculate_roi, get_market_predictions, agri_chat
from services.fertilizer_service import generate_fertilizer_prescription
from services.gemini_client import (
    call_gemini,
    call_groq,
    GEMINI_PRIMARY_MODEL,
    GEMINI_FALLBACK_MODEL,
    GEMINI_TEXT_MODEL,
    GEMINI_VISION_MODEL,
    GROQ_TEXT_MODEL,
    GROQ_VISION_MODEL,
    GROQ_FALLBACK_MODEL,
)

# ── Twilio imports with safe fallbacks (optional for cloud deployment) ──
try:
    from agrishield_twilio import (
        send_sms, make_voice_call,
        format_crop_alert, format_voice_alert,
        generate_welcome_twiml, handle_voice_input, generate_alert_call_twiml,
        FARMER_PHONE_NUMBER,
    )
    TWILIO_AVAILABLE = True
except Exception as _t_err:
    print(f"[AgriShield] Twilio optional/disabled: {_t_err}")
    TWILIO_AVAILABLE = False
    FARMER_PHONE_NUMBER = os.getenv("FARMER_PHONE_NUMBER", "+910000000000")
    def send_sms(*a, **kw): return {"success": False, "error": "Twilio not configured"}
    def make_voice_call(*a, **kw): return {"success": False, "error": "Twilio not configured"}
    def format_crop_alert(d): return f"Alert: {d.get('crop_name', 'Crop')}"
    def format_voice_alert(d): return f"Fasal update: {d.get('crop_name', '')}"
    def generate_welcome_twiml(): return "<Response><Say>AgriShield</Say></Response>"
    def handle_voice_input(*a, **kw): return "<Response><Say>OK</Say></Response>"
    def generate_alert_call_twiml(*a, **kw): return "<Response><Say>Alert</Say></Response>"

load_dotenv(override=True)
app = Flask(__name__)
CORS(app)

DATA_FILE = "last_scan.json"
UPLOAD_FOLDER = "stored_crops"
SOIL_UPLOAD_FOLDER = "stored_soil"
ALERT_HISTORY_FILE = os.path.join("project_data", "alert_history.json")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(SOIL_UPLOAD_FOLDER, exist_ok=True)
os.makedirs("project_data", exist_ok=True)

# =========================================================================
# 📡 PRODUCTION-GRADE STRUCTURED LOGGING & MONITORING
# =========================================================================
class RequestFormatter(logging.Formatter):
    def format(self, record):
        if not hasattr(record, 'request_id'):
            try:
                record.request_id = getattr(g, 'request_id', 'SYSTEM')
            except Exception:
                record.request_id = 'SYSTEM'
        return super().format(record)

logger = logging.getLogger("AgriShieldAPI")
logger.setLevel(logging.INFO)
_log_handler = logging.StreamHandler(sys.stdout)
_log_handler.setFormatter(RequestFormatter('%(asctime)s [%(levelname)s] [Req:%(request_id)s] %(message)s', datefmt='%Y-%m-%d %H:%M:%S'))
logger.handlers = [_log_handler]
logger.propagate = False

SENSITIVE_KEYS = {'password', 'token', 'authorization', 'secret', 'key', 'api_key', 'apikey'}

def sanitize_data(data):
    """Scrub passwords, tokens, API keys and secrets from request logging."""
    if isinstance(data, dict):
        return {
            k: '***REDACTED***' if any(s in k.lower() for s in SENSITIVE_KEYS) else sanitize_data(v)
            for k, v in data.items()
        }
    elif isinstance(data, list):
        return [sanitize_data(i) for i in data]
    return data

def get_requested_language():
    """
    Resolves client language preference ('hi' or 'en'):
    1. Custom Header 'X-App-Language'
    2. Standard Header 'Accept-Language'
    3. Query param 'lang' or 'language'
    4. Form field 'language' or 'lang'
    5. JSON body 'language' or 'lang'
    Defaults to 'en'.
    """
    lang = request.headers.get('X-App-Language')
    if not lang:
        accept_lang = request.headers.get('Accept-Language', '')
        if 'hi' in accept_lang.lower():
            lang = 'hi'
    if not lang:
        lang = request.args.get('lang') or request.args.get('language')
    if not lang and request.is_json:
        try:
            body = request.get_json(silent=True) or {}
            if isinstance(body, dict):
                lang = body.get('language') or body.get('lang')
        except Exception:
            pass
    if not lang and request.form:
        lang = request.form.get('language') or request.form.get('lang')

    if lang and str(lang).strip().lower().startswith('hi'):
        return 'hi'
    return 'en'


ENDPOINT_TAGS = {
    '/predict': '🌾 [CROP SCAN AI]',
    '/analyze-soil': '🧪 [SOIL SCAN AI]',
    '/soil-plant-recommendations': '🌱 [SOIL RECOMMENDATIONS]',
    '/soil-crop-recommendations': '🌽 [CROP RECOMMENDATIONS]',
    '/recovery-advice': '💊 [RECOVERY ADVICE]',
    '/roi-calculate': '💰 [ROI CALCULATOR]',
    '/market-predictions': '📈 [MARKET PREDICTIONS]',
    '/agri-chat': '💬 [FARMER CHATBOT]',
    '/fertilizer-prescription': '🌿 [FERTILIZER ADVISOR]',
    '/weather-advisory': '⛅ [WEATHER ADVISORY]',
    '/alert-history': '📋 [ALERT HISTORY]',
    '/send-alert': '🚨 [SEND TWILIO ALERT]',
    '/mandi-prices': '🏪 [MANDI PRICES]',
    '/govt-schemes': '🏛️ [GOVT SCHEMES]',
    '/last-scan': '🔍 [LAST SCAN]',
    '/ai-info': '🤖 [AI INFO]',
}


@app.before_request
def log_incoming_api_call():
    g.start_time = time.time()
    # Accept client trace ID or generate a unique request correlation ID
    g.request_id = request.headers.get('X-Request-ID') or uuid.uuid4().hex[:10]

    if request.path.startswith('/favicon.ico'):
        return None

    client_ip = request.remote_addr or 'Unknown'
    lang = get_requested_language()

    log_payload = ""
    if request.is_json:
        try:
            raw_body = request.get_json(silent=True)
            if raw_body:
                clean_body = sanitize_data(raw_body)
                body_str = json.dumps(clean_body, ensure_ascii=False)
                if len(body_str) > 160:
                    body_str = body_str[:160] + "..."
                log_payload = f"Payload: {body_str}"
        except Exception:
            pass
    elif request.files:
        files = list(request.files.keys())
        log_payload = f"Files: {files}"

    query_str = ""
    if request.args:
        clean_args = sanitize_data(dict(request.args))
        query_str = f"Query: {clean_args}"

    tag = ENDPOINT_TAGS.get(request.path, f"⚡ [{request.path}]")
    sep = "=" * 65
    print(f"\n{sep}", flush=True)
    print(f" 📥 {tag} ---> {request.method} {request.path}", flush=True)
    print(f"  📱 Caller IP : {client_ip}", flush=True)
    print(f"  🌐 Language  : {lang.upper()} ({'Hindi' if lang == 'hi' else 'English'})", flush=True)
    print(f"  🆔 RequestID : {g.request_id}", flush=True)
    if query_str:
        print(f"  🔍 {query_str}", flush=True)
    if log_payload:
        print(f"  📦 {log_payload}", flush=True)
    print(f"{sep}\n", flush=True)

    logger.info(f"➡️ INCOMING {request.method} {request.path} | Client: {client_ip} | Lang: {lang} | {query_str} {log_payload}")


@app.after_request
def log_outgoing_api_response(response):
    req_id = getattr(g, 'request_id', '--------')
    response.headers['X-Request-ID'] = req_id

    if request.path.startswith('/favicon.ico'):
        return response

    duration_ms = 0.0
    if hasattr(g, 'start_time'):
        duration_ms = round((time.time() - g.start_time) * 1000, 2)

    status = response.status_code
    icon = "✅" if status < 400 else "❌"

    tag = ENDPOINT_TAGS.get(request.path, f"⚡ [{request.path}]")
    sep = "-" * 65
    print(f"\n{sep}", flush=True)
    print(f" 📤 {icon} {tag} <--- {request.method} {request.path} [{status}] ({duration_ms}ms)", flush=True)
    print(f"  🆔 RequestID : {req_id}", flush=True)
    print(f"{sep}\n", flush=True)

    logger.info(f"⬅️ {icon} COMPLETED {request.method} {request.path} | Status: {status} | Duration: {duration_ms}ms")
    return response


@app.errorhandler(Exception)
def handle_unhandled_exception(e):
    req_id = getattr(g, 'request_id', '--------')
    duration_ms = 0.0
    if hasattr(g, 'start_time'):
        duration_ms = round((time.time() - g.start_time) * 1000, 2)

    print(f"\n{'!' * 65}", flush=True)
    print(f" 💥 UNHANDLED ERROR on {request.method} {request.path} ({duration_ms}ms)", flush=True)
    print(f"  Details: {str(e)}", flush=True)
    print(f"  RequestID: {req_id}", flush=True)
    print(f"{'!' * 65}\n", flush=True)

    logger.error(f"💥 UNHANDLED ERROR on {request.method} {request.path} ({duration_ms}ms) -> {str(e)}", exc_info=True)
    return jsonify({
        "status": "Error",
        "error": "Internal Server Error",
        "message": str(e),
        "request_id": req_id
    }), 500


# ========================
# 1. CROP ANALYSIS (Gemini Vision AI)
# ========================
@app.route('/predict', methods=['POST'])
def predict():
    try:
        lang = get_requested_language()
        if 'file' not in request.files:
            return jsonify({"error": "No file uploaded", "request_id": getattr(g, 'request_id', '')}), 400

        file = request.files['file']
        filename = f"crop_{len(os.listdir(UPLOAD_FOLDER)) + 1}.jpg"
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)
        logger.info(f"Image saved: {filepath} | Target Language: {lang}")

        analysis_data = analyze_crop_with_groq(filepath, language=lang)
        if "error" in analysis_data:
            err_msg = str(analysis_data["error"])
            status_code = 429 if ("429" in err_msg or "quota" in err_msg.lower()) else 500
            return jsonify({
                "status": "Error",
                "error": err_msg,
                "message": "AI analysis unavailable. Quota limit reached or network drop. Please retry in a few moments.",
                "request_id": getattr(g, 'request_id', '')
            }), status_code

        with open(DATA_FILE, 'w', encoding='utf-8') as f:
            json.dump(analysis_data, f, indent=2, ensure_ascii=False)

        return jsonify({
            "status": "Success",
            "data": analysis_data,
            "confidence": analysis_data.get("confidence", 0),
            "language": lang,
            "request_id": getattr(g, 'request_id', '')
        })
    except Exception as e:
        logger.error(f"Predict error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 2. LAST SCAN (Home Page)
# ========================
@app.route('/last-scan', methods=['GET'])
def get_last_scan():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            return jsonify({"status": "Success", "data": json.load(f)})
    return jsonify({"error": "No scan found"})


# ========================
# 3. WEATHER ADVISORY (NASA POWER API)
# ========================
@app.route('/weather-advisory', methods=['GET'])
def weather_advisory():
    try:
        lat = request.args.get('lat', '22.7196')
        lon = request.args.get('lon', '75.8577')
        lang = get_requested_language()
        weather_data = get_recent_weather(float(lat), float(lon), language=lang)
        return jsonify(weather_data)
    except Exception as e:
        logger.error(f"Weather error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ==========================================
# 3.1 SMART SPRAY WINDOW ADVISOR (Open-Meteo)
# ==========================================
@app.route('/spray-advisor', methods=['GET'])
def spray_advisor():
    try:
        lat = request.args.get('lat', '22.7196')
        lon = request.args.get('lon', '75.8577')
        lang = get_requested_language()
        advisor_data = get_spray_advisory(float(lat), float(lon), language=lang)
        return jsonify({"status": "Success", "data": advisor_data, "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"Spray Advisor error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ==========================================
# 3.2 FERTILIZER PRESCRIPTION (Khad Parchi)
# ==========================================
@app.route('/fertilizer-prescription', methods=['POST'])
def fertilizer_prescription():
    try:
        data = request.get_json(silent=True) or {}
        lang = get_requested_language()
        crop_name = data.get('crop_name', 'Wheat')
        land_size = float(data.get('land_size', 1.0))
        unit = data.get('unit', 'Acre')
        crop_age_days = int(data.get('crop_age_days', 20))
        soil_type = data.get('soil_type', 'सामान्य दोमट (Loam)')

        prescription = generate_fertilizer_prescription(
            crop_name=crop_name,
            land_size=land_size,
            unit=unit,
            crop_age_days=crop_age_days,
            soil_type=soil_type,
            language=lang
        )
        return jsonify({"status": "Success", "data": prescription, "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"Fertilizer prescription error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 4. MANDI PRICES (Gemini AI — Indore Mandi)
# Govt Reference: https://mpeuparjan.nic.in/
# ========================
@app.route('/mandi-prices', methods=['GET'])
def mandi_prices():
    try:
        prices = get_market_prices()
        return jsonify(prices)
    except Exception as e:
        logger.error(f"Market error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 5. SOIL ANALYSIS
# ========================
@app.route('/analyze-soil', methods=['POST'])
def analyze_soil():
    try:
        lang = get_requested_language()
        if 'file' not in request.files:
            return jsonify({"error": "No file uploaded", "request_id": getattr(g, 'request_id', '')}), 400
        file = request.files['file']
        filename = f"soil_{len(os.listdir(SOIL_UPLOAD_FOLDER)) + 1}.jpg"
        filepath = os.path.join(SOIL_UPLOAD_FOLDER, filename)
        file.save(filepath)
        logger.info(f"Soil image saved: {filepath} | Language: {lang}")
        result = analyze_soil_image(filepath, language=lang)
        if "error" in result:
            return jsonify({"status": "Error", "error": result["error"], "request_id": getattr(g, 'request_id', '')}), 500
        return jsonify({"status": "Success", "data": result, "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"Soil analysis error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


@app.route('/soil-plant-recommendations', methods=['POST'])
def soil_plant_recs():
    try:
        lang = get_requested_language()
        soil_data = request.get_json(silent=True) or {}
        result = get_plant_recommendations(soil_data, language=lang)
        if "error" in result:
            return jsonify({"status": "Error", "error": result["error"], "request_id": getattr(g, 'request_id', '')}), 500
        return jsonify({"status": "Success", "data": result.get("plants", []), "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"Plant recommendation error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


@app.route('/soil-crop-recommendations', methods=['POST'])
def soil_crop_recs():
    try:
        lang = get_requested_language()
        import json as jlib
        soil_data = jlib.loads(request.form.get('soil_data', '{}'))
        season = request.form.get('season', None)
        field_files = request.files.getlist('field_images')
        if len(field_files) < 3:
            return jsonify({"error": "Minimum 3 field photos required", "request_id": getattr(g, 'request_id', '')}), 400
        saved_paths = []
        for i, f in enumerate(field_files):
            fp = os.path.join(SOIL_UPLOAD_FOLDER, f"field_{i+1}.jpg")
            f.save(fp)
            saved_paths.append(fp)
        result = get_crop_recommendations(soil_data, saved_paths, season=season, language=lang)
        if "error" in result:
            return jsonify({"status": "Error", "error": result["error"], "request_id": getattr(g, 'request_id', '')}), 500
        return jsonify({"status": "Success", "data": result.get("crops", []), "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"Crop recommendation error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 6. RECOVERY ADVISOR
# ========================
@app.route('/recovery-advice', methods=['POST'])
def recovery_advice():
    try:
        lang = get_requested_language()
        data = request.get_json(silent=True) or {}
        if not data:
            return jsonify({"error": "No data provided", "request_id": getattr(g, 'request_id', '')}), 400
        result = get_recovery_advice(data, language=lang)
        if "error" in result:
            return jsonify({"status": "Error", "error": result["error"], "request_id": getattr(g, 'request_id', '')}), 500
        return jsonify({"status": "Success", "data": result, "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"Recovery advice error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 7. ROI CALCULATOR
# ========================
@app.route('/roi-calculate', methods=['POST'])
def roi_calculate():
    try:
        lang = get_requested_language()
        data = request.get_json(silent=True) or {}
        if not data:
            return jsonify({"error": "No data provided", "request_id": getattr(g, 'request_id', '')}), 400
        investment = int(data.get('investment_amount', 50000))
        land_size = float(data.get('land_size', 5))
        crop_name = data.get('crop_name', 'General')
        result = calculate_roi(investment, land_size, crop_name, language=lang)
        if "error" in result:
            return jsonify({"status": "Error", "error": result["error"], "request_id": getattr(g, 'request_id', '')}), 500
        return jsonify({"status": "Success", "data": result, "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"ROI calculation error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 8. MARKET PREDICTIONS
# ========================
@app.route('/market-predictions', methods=['GET'])
def market_predictions():
    try:
        lang = get_requested_language()
        result = get_market_predictions(language=lang)
        if "error" in result:
            return jsonify({"status": "Error", "error": result["error"], "request_id": getattr(g, 'request_id', '')}), 500
        return jsonify({"status": "Success", "data": result.get("predictions", []), "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"Market prediction error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 9. AGRIBOT CHATBOT
# ========================
@app.route('/agri-chat', methods=['POST'])
def agri_chat_route():
    try:
        data = request.get_json(silent=True) or {}
        if not data or 'message' not in data:
            return jsonify({"error": "Message is required", "request_id": getattr(g, 'request_id', '')}), 400
        message = data['message']
        language = get_requested_language()
        history = data.get('history', [])
        result = agri_chat(message, language, history)
        if "error" in result:
            return jsonify({"status": "Error", "error": result["error"], "request_id": getattr(g, 'request_id', '')}), 500
        return jsonify({"status": "Success", "data": result, "request_id": getattr(g, 'request_id', '')})
    except Exception as e:
        logger.error(f"AgriBot chat error: {e}", exc_info=True)
        return jsonify({"error": str(e), "request_id": getattr(g, 'request_id', '')}), 500


# ========================
# 10. TWILIO VOICE WEBHOOKS — IVR with Groq AI
# ========================
@app.route('/voice-incoming', methods=['POST', 'GET'])
def voice_incoming():
    """Twilio webhook — farmer calls this number → AI welcomes in Hindi."""
    print("[AgriShield] 📞 Incoming call received! Generating Hindi welcome...")
    twiml = generate_welcome_twiml()
    return twiml, 200, {'Content-Type': 'application/xml'}


@app.route('/voice-respond', methods=['POST'])
def voice_respond():
    """Twilio webhook — farmer speaks → Groq AI answers in Hindi."""
    speech = request.form.get('SpeechResult', '')
    print(f"[AgriShield] 🗣️ Farmer said: '{speech}'")

    if not speech:
        from twilio.twiml.voice_response import VoiceResponse, Gather
        response = VoiceResponse()
        gather = Gather(input='speech', action='/voice-respond', method='POST',
                        language='hi-IN', speech_timeout='auto', timeout=10)
        gather.say('भैया, मुझे आपकी आवाज़ नहीं सुनाई दी। कृपया अपना सवाल दोबारा बोलिए।',
                   language='hi-IN', voice='Polly.Aditi')
        response.append(gather)
        response.say('धन्यवाद किसान भाई! आपका दिन शुभ हो। जय किसान!', language='hi-IN', voice='Polly.Aditi')
        return str(response), 200, {'Content-Type': 'application/xml'}

    twiml = handle_voice_input(speech)
    print("[AgriShield] 🤖 AI response generated for farmer")
    return twiml, 200, {'Content-Type': 'application/xml'}


# ========================
# 11. TWILIO OUTGOING CALL — Groq AI Agriculture Call
# ========================
VOICE_AGRI_PROMPT = """You are AgriShield AI — a FEMALE assistant calling a farmer to give agriculture advice.

IMPORTANT: You are FEMALE. Always use FEMININE Hindi verb forms:
- "मैं बता सकती हूं" (NOT "सकता हूं")
- "मैं आई हूं" (NOT "आया हूं")
- "मैंने सोचा" with feminine endings

Generate a SHORT, helpful voice message (3-5 sentences) IN HINDI (Devanagari script).
The message should:
1. Greet warmly: "नमस्ते किसान भाई!"
2. Introduce yourself: "मैं AgriShield AI हूं"
3. Give useful farming tip/advice in simple feminine Hindi
4. Be practical for Indian farmers
5. End with: "आपका दिन शुभ हो। जय किसान!"

If crop data is provided, give specific advice about that crop.

{crop_info}

Generate ONLY the spoken text in HINDI Devanagari with FEMININE verb forms.
No formatting, no quotes, no special characters, no English.
Keep it under 200 words."""


@app.route('/send-alert', methods=['POST'])
def send_alert():
    """Send voice call alert to farmer with Groq AI agriculture content."""
    try:
        data = request.get_json() or {}
        phone = data.get('phone', FARMER_PHONE_NUMBER)
        scan_data = data.get('scan_data', {})
        message = data.get('message', '')
        level = data.get('level', 'INFO')

        results = []

        # ── Generate AI Agriculture Message via Gemini ──
        print("[AgriShield] 🤖 Generating AI agriculture message via Gemini...")

        if scan_data:
            crop_info = (
                f"Crop: {scan_data.get('crop_name', 'Unknown')}\n"
                f"Health Score: {scan_data.get('health_score', 'N/A')}/100\n"
                f"Disease: {scan_data.get('disease', 'None')}\n"
                f"Treatment: {scan_data.get('treatment', 'N/A')}\n"
                f"Fertilizer: {scan_data.get('fertilizer_recommendation', 'N/A')}"
            )
        elif message:
            crop_info = f"Context: {message}"
        else:
            crop_info = "No specific crop data. Give general seasonal farming advice for Indian farmers."

        ai_prompt = VOICE_AGRI_PROMPT.format(crop_info=crop_info)

        gemini_result = call_gemini(
            prompt=ai_prompt,
            temperature=0.6,
            max_tokens=300,
            timeout=15,
            tag="VoiceCall"
        )

        if gemini_result.get("success"):
            voice_text = gemini_result["raw"].strip().strip('"\'')
            print(f"[AgriShield] 🤖 AI Message: {voice_text[:100]}...")
        else:
            if scan_data:
                voice_text = format_voice_alert(scan_data)
            else:
                voice_text = message or "Hello farmer! This is AgriShield AI. Please check your crops regularly. Use proper irrigation and fertilizers. Happy farming!"
            print(f"[AgriShield] ⚠️ Gemini failed, using fallback message")

        # ── Make the voice call ──
        print(f"[AgriShield] 📞 Calling {phone}...")
        call_result = make_voice_call(to=phone, twiml_text=voice_text)
        results.append(call_result)

        if call_result.get("success"):
            print(f"[AgriShield] ✅ Call initiated! SID: {call_result.get('sid')}")
        else:
            print(f"[AgriShield] ❌ Call failed: {call_result.get('error')}")

        # Save to alert history
        alert_entry = {
            'timestamp': datetime.now().isoformat(),
            'type': 'crop_scan' if scan_data else 'manual',
            'alert_level': level,
            'crop_name': scan_data.get('crop_name', ''),
            'health_score': scan_data.get('health_score', ''),
            'phone': phone,
            'ai_message': voice_text[:200],
            'results': results,
        }
        _save_alert_history(alert_entry)

        return jsonify({'status': 'Success', 'results': results, 'ai_message': voice_text})
    except Exception as e:
        print(f'[AgriShield] Alert Error: {e}')
        return jsonify({'error': str(e)}), 500


@app.route('/alert-history', methods=['GET'])
def alert_history():
    """Get alert history."""
    try:
        limit = int(request.args.get('limit', 50))
        history = _load_alert_history()
        return jsonify({'status': 'Success', 'data': history[:limit]})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def _save_alert_history(entry):
    history = _load_alert_history()
    history.insert(0, entry)
    history = history[:200]
    with open(ALERT_HISTORY_FILE, 'w') as f:
        json.dump(history, f, indent=2)


def _load_alert_history():
    if os.path.exists(ALERT_HISTORY_FILE):
        with open(ALERT_HISTORY_FILE, 'r') as f:
            return json.load(f)
    return []


# ========================
# 12. GOVERNMENT SCHEMES
# ========================
@app.route('/govt-schemes', methods=['GET'])
def govt_schemes():
    """Get list of active Indian government agricultural schemes."""
    try:
        schemes = [
            {
                "title": "Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)",
                "description": "Provides income support of ₹6,000 per year in three equal installments to all landholding farmer families across the country.",
                "benefit": "₹6,000 / Year",
                "category": "Income Support",
                "source": "Ministry of Agriculture",
                "date": "May 2026",
                "link": "https://pmkisan.gov.in/"
            },
            {
                "title": "Pradhan Mantri Fasal Bima Yojana (PMFBY)",
                "description": "Yield-based crop insurance scheme that protects farmers against crop loss/damage due to natural calamities, pests, and diseases with extremely low premiums.",
                "benefit": "Financial Cover for Crop Loss",
                "category": "Crop Insurance",
                "source": "Ministry of Agriculture & Farmers Welfare",
                "date": "May 2026",
                "link": "https://pmfby.gov.in/"
            },
            {
                "title": "Kisan Credit Card (KCC) Scheme",
                "description": "Provides farmers with timely credit and short-term loans for purchasing seeds, fertilizers, pesticides, and other agricultural requirements at highly subsidized interest rates.",
                "benefit": "Subsidized loans (up to 4% effective interest)",
                "category": "Agricultural Credit",
                "source": "Reserve Bank of India & NABARD",
                "date": "May 2026",
                "link": "https://www.pib.gov.in/PressReleasePage.aspx?PRID=1646700"
            },
            {
                "title": "Pradhan Mantri Krishi Sinchayee Yojana (PMKSY)",
                "description": "Focuses on developing irrigation sources, water conservation, and promoting micro-irrigation technologies like drip and sprinkler system under 'Per Drop More Crop'.",
                "benefit": "Up to 55% Micro-irrigation Subsidy",
                "category": "Irrigation Support",
                "source": "Ministry of Agriculture & Farmers Welfare",
                "date": "May 2026",
                "link": "https://pmksy.gov.in/"
            },
            {
                "title": "Soil Health Card Scheme",
                "description": "Provides farmers with detailed soil health cards containing chemical analysis of their soil and tailor-made fertilizer / nutrient recommendations to boost crop yield.",
                "benefit": "Free Soil Testing & Health Card",
                "category": "Soil Health",
                "source": "Department of Agriculture & Farmers Welfare",
                "date": "May 2026",
                "link": "https://soilhealth.dac.gov.in/"
            },
            {
                "title": "Paramparagat Krishi Vikas Yojana (PKVY)",
                "description": "Promotes organic farming, soil fertility enhancement, and chemical-free agriculture using PGS organic certification and cluster-based adoption models.",
                "benefit": "₹50,000 / Hectare financial assistance",
                "category": "Organic Farming",
                "source": "Department of Agriculture & Farmers Welfare",
                "date": "May 2026",
                "link": "https://dapgd.gov.in/"
            },
            {
                "title": "National Agriculture Market (e-NAM)",
                "description": "A pan-India electronic trading portal that networks existing APMC mandis to create a unified national market for agricultural commodities with transparent price discovery.",
                "benefit": "Direct Access to Unified Digital Market",
                "category": "Market & Trade",
                "source": "Small Farmers Agribusiness Consortium (SFAC)",
                "date": "May 2026",
                "link": "https://enam.gov.in/"
            }
        ]
        return jsonify({"status": "Success", "data": schemes})
    except Exception as e:
        print(f"[AgriShield] Govt Schemes Error: {e}")
        return jsonify({"error": str(e)}), 500


# ========================
# 13. HEALTH CHECK
# ========================
@app.route('/', methods=['GET'])
def health_check():
    return jsonify({
        "status": "AgriShield AI Backend Running",
        "version": "5.0",
        "ai_provider": "Google Gemini API (fastest flash-lite inference)",
        "primary_model": GEMINI_PRIMARY_MODEL,
        "vision_model": GEMINI_VISION_MODEL,
        "fallback_model": GEMINI_FALLBACK_MODEL,
        "twilio": "agrishield_twilio module",
        "endpoints": [
            "/predict", "/last-scan", "/weather-advisory", "/mandi-prices",
            "/analyze-soil", "/soil-plant-recommendations", "/soil-crop-recommendations",
            "/recovery-advice", "/roi-calculate", "/market-predictions", "/agri-chat",
            "/voice-incoming", "/voice-respond",
            "/send-alert", "/alert-history", "/govt-schemes", "/ai-info"
        ]
    })


# ========================
# 14. AI MODEL INFO
# ========================
@app.route('/ai-info', methods=['GET'])
def ai_info():
    """Returns current AI model configuration."""
    return jsonify({
        "status": "Success",
        "data": {
            "provider": "Google Gemini",
            "provider_url": "https://generativelanguage.googleapis.com",
            "hardware": "Google Cloud TPU",
            "models": {
                "text": {
                    "id": GEMINI_TEXT_MODEL,
                    "name": "Gemini 2.5 Flash Lite",
                    "by": "Google DeepMind",
                    "params": "Flash Lite",
                    "context_window": 1048576,
                    "use": "Fastest text generation: chat, analysis, predictions, ROI"
                },
                "vision": {
                    "id": GEMINI_VISION_MODEL,
                    "name": "Gemini 2.5 Flash Lite Vision",
                    "by": "Google DeepMind",
                    "params": "Multimodal Flash Lite",
                    "context_window": 1048576,
                    "use": "Fastest crop & soil image analysis"
                },
                "fallback": {
                    "id": GEMINI_FALLBACK_MODEL,
                    "name": "Gemini 3.1 Flash Lite",
                    "by": "Google DeepMind",
                    "params": "Flash Lite Preview",
                    "context_window": 1048576,
                    "use": "Ultra-fast auto-fallback"
                }
            }
        }
    })


def get_local_ip():
    """Detect the active local LAN / Wi-Fi IP address."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0.5)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        try:
            return socket.gethostbyname(socket.gethostname())
        except Exception:
            return "127.0.0.1"


if __name__ == '__main__':
    port = int(os.getenv("PORT", 5000))
    local_ip = get_local_ip()

    print("=" * 65, flush=True)
    print("  🌾 AgriShield AI Backend v5.0 (Google Gemini AI + Twilio)", flush=True)
    print(f"  Primary AI   : {GEMINI_PRIMARY_MODEL}", flush=True)
    print(f"  Vision AI    : {GEMINI_VISION_MODEL}", flush=True)
    print(f"  Fallback     : {GEMINI_FALLBACK_MODEL}", flush=True)
    print("=" * 65, flush=True)
    print(f"  🖥️  Local Host : http://127.0.0.1:{port}", flush=True)
    print(f"  📱 Wi-Fi IP   : http://{local_ip}:{port} (Physical phone connection)", flush=True)
    print(f"  📞 Twilio Tel : {FARMER_PHONE_NUMBER}", flush=True)
    print("=" * 65, flush=True)
    print(f"  🟢 Server is live & listening! Ready for mobile requests...\n", flush=True)

    app.run(
        host=os.getenv("HOST", "0.0.0.0"),
        port=port,
        debug=True
    )