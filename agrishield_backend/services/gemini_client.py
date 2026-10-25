"""
Central AI API Client — Google Gemini (Fastest Models)
======================================================
Single source of truth for all AI API interactions across AgriShield.

Primary Model:
  gemini-2.5-flash-lite (Fastest inference: ~1.8s text, ~3.3s vision, native multimodal + structured JSON)

Fallback Model:
  gemini-3.1-flash-lite / gemini-3.5-flash-lite

All API keys loaded from .env (GEMINI_API_KEY)
Includes connection resilience (retry on TCP connection reset, wsarecv 10054, and network drops).
"""

import os
import base64
import json
import re
import time
import requests
from requests.adapters import HTTPAdapter
from urllib3.util import Retry
from dotenv import load_dotenv

# Load .env searching multiple candidate locations
_possible_env_paths = [
    os.path.join(os.path.dirname(__file__), '..', '.env'),
    os.path.join(os.path.dirname(__file__), '..', '..', '.env'),
    os.path.join(os.getcwd(), '.env'),
]
for p in _possible_env_paths:
    if os.path.exists(p):
        load_dotenv(p, override=True)

# ── Config ───────────────────────────────────────────────────
GEMINI_API_KEY = (
    os.getenv("GEMINI_API_KEY")
    or os.getenv("GROQ_API_KEY")
    or ""  # Set GEMINI_API_KEY in your .env file — see .env.example
)

GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
GEMINI_OPENAI_URL = f"{GEMINI_BASE_URL}/openai/chat/completions"

# ── Model Constants (Fastest Gemini Flash Models) ────────────
# Blacklist known exhausted or hanging models from being default primary
EXHAUSTED_OR_BROKEN_MODELS = {"gemini-2.5-flash-lite", "gemini-3.1-flash-lite"}

_raw_primary = os.getenv("GEMINI_MODEL", "gemini-3-flash-preview")
if _raw_primary in EXHAUSTED_OR_BROKEN_MODELS:
    _raw_primary = "gemini-3-flash-preview"
GEMINI_PRIMARY_MODEL = _raw_primary

_raw_fallback = os.getenv("GEMINI_FALLBACK_MODEL", "gemini-3.5-flash-lite")
if _raw_fallback in EXHAUSTED_OR_BROKEN_MODELS:
    _raw_fallback = "gemini-3.5-flash-lite"
GEMINI_FALLBACK_MODEL = _raw_fallback

GEMINI_TEXT_MODEL   = GEMINI_PRIMARY_MODEL
GEMINI_VISION_MODEL = GEMINI_PRIMARY_MODEL

# Automatic fallback cascade in case of quota (429), high demand (503), or deprecation (404)
GEMINI_MODEL_CASCADE = [
    GEMINI_PRIMARY_MODEL,
    GEMINI_FALLBACK_MODEL,
    "gemini-3-flash-preview",
    "gemini-3.5-flash-lite",
    "gemini-3.1-flash-lite",
    "gemini-2.5-flash-lite",
]

# ── Backward Compatibility Aliases for Groq ───────────────────
GROQ_API_KEY        = GEMINI_API_KEY
GROQ_TEXT_MODEL     = GEMINI_TEXT_MODEL
GROQ_VISION_MODEL   = GEMINI_VISION_MODEL
GROQ_FALLBACK_MODEL = GEMINI_FALLBACK_MODEL


# ── Robust Session Management (Handles TCP Resets & IPv6 Drops) ─
def _create_robust_session() -> requests.Session:
    """Create a requests session with retries for connection resets."""
    s = requests.Session()
    retries = Retry(
        total=3,
        backoff_factor=0.6,
        status_forcelist=[429, 500, 502, 503, 504],
        raise_on_status=False,
    )
    adapter = HTTPAdapter(max_retries=retries, pool_connections=10, pool_maxsize=10)
    s.mount("https://", adapter)
    s.mount("http://", adapter)
    return s

_session = _create_robust_session()


# ── Shared Helpers ───────────────────────────────────────────
def encode_image_to_base64(image_path: str) -> str:
    """Encode an image file to base64 string."""
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def get_mime_type(image_path: str) -> str:
    """Get MIME type from file extension."""
    ext = image_path.lower().split('.')[-1]
    mime_map = {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }
    return mime_map.get(ext, "image/jpeg")


def parse_json_response(raw_text: str) -> str:
    """Strip markdown fences from response text."""
    text = raw_text.strip()
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()
    return text


def extract_json_object(text: str) -> str:
    """Find the first JSON object {...} in text."""
    match = re.search(r'\{[\s\S]*\}', text)
    return match.group() if match else text


def extract_json_array(text: str) -> str:
    """Find the first JSON array [...] in text."""
    match = re.search(r'\[[\s\S]*\]', text)
    return match.group() if match else text


def _repair_truncated_json_array(text: str):
    """Try to repair a truncated JSON array by finding the last complete object."""
    start = text.find('[')
    if start == -1:
        return None
    last_brace = text.rfind('}')
    if last_brace == -1:
        return None
    repaired = text[start:last_brace + 1].rstrip().rstrip(',') + ']'
    try:
        result = json.loads(repaired)
        print(f"[AgriShield] JSON array repaired successfully ({len(result)} items)")
        return result
    except json.JSONDecodeError:
        return None


def _repair_truncated_json_object(text: str):
    """Try to repair a truncated JSON object by removing trailing incomplete fields."""
    start = text.find('{')
    if start == -1:
        return None
    cleaned = text[start:].strip()

    # Try quick suffixes
    for suffix in ['', '"}', '"]}', '"]}}', '}', ']}']:
        try:
            return json.loads(cleaned + suffix)
        except Exception:
            pass

    # Try unwinding broken property at last comma
    last_comma = cleaned.rfind(',')
    while last_comma != -1:
        candidate = cleaned[:last_comma].rstrip() + '\n}'
        try:
            res = json.loads(candidate)
            print(f"[AgriShield] JSON object repaired successfully ({len(res)} keys recovered)")
            return res
        except Exception:
            last_comma = cleaned[:last_comma].rfind(',')

    return None


# ── Core Gemini API Call with Auto-Retry ───────────────────────
def call_gemini(
    prompt: str,
    images: list = None,
    temperature: float = 0.3,
    max_tokens: int = 4096,
    timeout: int = 45,
    tag: str = "Gemini",
    response_json: bool = False,
    model: str = None,
) -> dict:
    """
    Call Google Gemini API with multimodal vision, text, and JSON formatting.
    Includes auto-retry on network drop/TCP connection reset.
    """
    if not GEMINI_API_KEY:
        return {"error": "GEMINI_API_KEY is not configured", "success": False}

    primary = model or GEMINI_PRIMARY_MODEL
    # Build unique cascade starting with the requested model
    candidates = [primary]
    for m in GEMINI_MODEL_CASCADE:
        if m and m not in candidates:
            candidates.append(m)

    # Build Gemini contents parts
    parts = [{"text": prompt}]
    if images:
        for img_path in images:
            if os.path.exists(img_path):
                b64 = encode_image_to_base64(img_path)
                mime = get_mime_type(img_path)
                parts.append({
                    "inline_data": {
                        "mime_type": mime,
                        "data": b64
                    }
                })
            else:
                print(f"[AgriShield][{tag}] Warning: Image file not found: {img_path}")

    generation_config = {
        "temperature": temperature,
        "maxOutputTokens": max_tokens,
    }
    if response_json:
        generation_config["responseMimeType"] = "application/json"

    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": generation_config
    }

    last_error = "Unknown error"

    for idx, candidate_model in enumerate(candidates):
        url = f"{GEMINI_BASE_URL}/models/{candidate_model}:generateContent?key={GEMINI_API_KEY}"

        def _execute_post(target_url, attempt=1):
            try:
                return _session.post(target_url, json=payload, timeout=timeout)
            except (requests.exceptions.ConnectionError, requests.exceptions.ChunkedEncodingError, ConnectionResetError, OSError) as e:
                if attempt < 3:
                    print(f"[AgriShield][{tag}] ⚠️ Connection reset/drop ({e}), retrying {attempt+1}/3...")
                    time.sleep(1.0)
                    return _execute_post(target_url, attempt + 1)
                raise e

        try:
            retry_note = f" (fallback {idx}/{len(candidates)-1})" if idx > 0 else ""
            print(f"[AgriShield][{tag}] Calling Gemini ({candidate_model}){retry_note}...")
            t0 = time.time()
            resp = _execute_post(url)
            elapsed = round(time.time() - t0, 2)

            if resp.status_code == 200:
                data = resp.json()
                candidates_data = data.get("candidates", [])
                if candidates_data and "content" in candidates_data[0]:
                    raw_parts = candidates_data[0]["content"].get("parts", [])
                    raw = "".join([p.get("text", "") for p in raw_parts])
                    if idx > 0:
                        print(f"[AgriShield][{tag}] ✅ Fallback succeeded with {candidate_model}!")
                    print(f"[AgriShield][{tag}] Response received ({len(raw)} chars, {elapsed}s) from {candidate_model}")
                    return {"raw": raw, "success": True, "model": candidate_model}
                else:
                    finish_reason = candidates_data[0].get("finishReason", "UNKNOWN") if candidates_data else "NO_CANDIDATES"
                    print(f"[AgriShield][{tag}] No text content in candidate (reason: {finish_reason})")
                    last_error = f"Empty response from Gemini ({finish_reason})"
                    continue

            # Non-200 status code (e.g., 429 quota, 503 high demand, 404 deprecated)
            error_text = resp.text[:300]
            last_error = f"Gemini API Error: {resp.status_code} - {error_text}"
            print(f"[AgriShield][{tag}] ⚠️ Gemini Error {resp.status_code} on {candidate_model}: {error_text}")

            if idx < len(candidates) - 1:
                next_model = candidates[idx + 1]
                print(f"[AgriShield][{tag}] 🔄 Auto-failing over to next model: {next_model}...")
                continue

        except requests.exceptions.Timeout:
            print(f"[AgriShield][{tag}] ⚠️ Timeout after {timeout}s on {candidate_model}")
            last_error = f"API request timed out on {candidate_model} after {timeout}s"
            if idx < len(candidates) - 1:
                next_model = candidates[idx + 1]
                print(f"[AgriShield][{tag}] 🔄 Auto-failing over to next model: {next_model}...")
                continue
        except Exception as e:
            print(f"[AgriShield][{tag}] ⚠️ Error on {candidate_model}: {e}")
            last_error = str(e)
            if idx < len(candidates) - 1:
                continue

    return {"error": last_error, "success": False}


# ── Convenience: call + parse JSON object ────────────────────
def call_gemini_json_object(prompt: str, images: list = None, **kwargs) -> dict:
    """Call Gemini and parse response as JSON object {...}."""
    result = call_gemini(prompt, images=images, response_json=True, **kwargs)
    if not result.get("success"):
        result = call_gemini(prompt, images=images, response_json=False, **kwargs)
        if not result.get("success"):
            return {"error": result.get("error", "API Error")}

    try:
        text = parse_json_response(result["raw"])
        text = extract_json_object(text)
        return json.loads(text)
    except Exception as e:
        print(f"[AgriShield] JSON parse error: {e}")
        return {"error": "Failed to parse AI response as JSON"}


# ── Convenience: call + parse JSON array ─────────────────────
def call_gemini_json_array(prompt: str, images: list = None, **kwargs):
    """Call Gemini and parse response as JSON array [...]."""
    result = call_gemini(prompt, images=images, response_json=True, **kwargs)
    if not result.get("success"):
        result = call_gemini(prompt, images=images, response_json=False, **kwargs)
        if not result.get("success"):
            return {"error": result.get("error", "API Error")}

    try:
        text = parse_json_response(result["raw"])
        text = extract_json_array(text)
        return json.loads(text)
    except Exception as e:
        print(f"[AgriShield] JSON parse error: {e}, attempting repair...")
        repaired = _repair_truncated_json_array(text)
        if repaired is not None:
            return repaired
        return {"error": "Failed to parse AI response as JSON list"}


# ── Multi-turn Chat Support (AgriBot / IVR) with Retry ─────────
def call_gemini_chat(
    messages: list,
    temperature: float = 0.6,
    max_tokens: int = 1024,
    timeout: int = 30,
    tag: str = "AgriBot",
) -> dict:
    """
    Call Gemini for multi-turn chat using the OpenAI-compatible endpoint.
    Includes auto-retry on TCP connection reset or drop.
    """
    if not GEMINI_API_KEY:
        return {"error": "GEMINI_API_KEY is not configured", "success": False}

    headers = {
        "Authorization": f"Bearer {GEMINI_API_KEY}",
        "Content-Type": "application/json",
    }

    candidates = []
    for m in [GEMINI_PRIMARY_MODEL, GEMINI_FALLBACK_MODEL, "gemini-3-flash-preview", "gemini-3.5-flash-lite", "gemini-3.1-flash-lite", "gemini-2.5-flash-lite"]:
        if m and m not in candidates:
            candidates.append(m)

    last_error = "Unknown chat error"

    for idx, candidate_model in enumerate(candidates):
        def _do_chat_post(m_id, attempt=1):
            payload = {
                "model": m_id,
                "messages": messages,
                "temperature": temperature,
                "max_tokens": max_tokens,
            }
            try:
                return _session.post(GEMINI_OPENAI_URL, headers=headers, json=payload, timeout=timeout)
            except (requests.exceptions.ConnectionError, requests.exceptions.ChunkedEncodingError, ConnectionResetError, OSError) as e:
                if attempt < 3:
                    print(f"[AgriShield][{tag}] ⚠️ Connection drop in chat, retrying {attempt+1}/3...")
                    time.sleep(1.0)
                    return _do_chat_post(m_id, attempt + 1)
                raise e

        try:
            print(f"[AgriShield][{tag}] Calling Gemini Chat ({candidate_model})...")
            resp = _do_chat_post(candidate_model)

            if resp.status_code == 200:
                data = resp.json()
                reply = data["choices"][0]["message"]["content"]
                used_model = data.get("model", candidate_model)
                if idx > 0:
                    print(f"[AgriShield][{tag}] ✅ Chat succeeded with fallback model: {candidate_model}")
                return {
                    "reply": reply,
                    "success": True,
                    "model": used_model,
                }

            error_text = resp.text[:300]
            print(f"[AgriShield][{tag}] ⚠️ Chat Error {resp.status_code} on {candidate_model}: {error_text}")
            last_error = f"API Error: {resp.status_code} - {error_text}"

            if idx < len(candidates) - 1:
                next_model = candidates[idx + 1]
                print(f"[AgriShield][{tag}] 🔄 Auto-failing over chat to next model: {next_model}...")
                continue

        except requests.exceptions.Timeout:
            print(f"[AgriShield][{tag}] ⚠️ Chat timeout on {candidate_model}")
            last_error = "Request timed out. Please try again."
            if idx < len(candidates) - 1:
                continue
        except Exception as e:
            print(f"[AgriShield][{tag}] ⚠️ Chat Exception on {candidate_model}: {e}")
            last_error = str(e)
            if idx < len(candidates) - 1:
                continue

    return {"error": last_error, "success": False}


# ── Backward Compatibility API ───────────────────────────────
call_groq = call_gemini
call_groq_json_object = call_gemini_json_object
call_groq_json_array = call_gemini_json_array
call_groq_chat = call_gemini_chat
