"""
Compatibility Wrapper: groq_client -> gemini_client
===================================================
All AI features have transitioned to Google Gemini (Fastest: gemini-2.5-flash-lite).
This file re-exports everything from gemini_client to ensure 100% backward compatibility.
"""

from services.gemini_client import (
    GEMINI_API_KEY,
    GEMINI_PRIMARY_MODEL,
    GEMINI_FALLBACK_MODEL,
    GEMINI_TEXT_MODEL,
    GEMINI_VISION_MODEL,
    GROQ_API_KEY,
    GROQ_TEXT_MODEL,
    GROQ_VISION_MODEL,
    GROQ_FALLBACK_MODEL,
    encode_image_to_base64,
    get_mime_type,
    parse_json_response,
    extract_json_object,
    extract_json_array,
    call_gemini,
    call_gemini_json_object,
    call_gemini_json_array,
    call_gemini_chat,
    call_groq,
    call_groq_json_object,
    call_groq_json_array,
    call_groq_chat,
    _repair_truncated_json_object,
)

__all__ = [
    "GEMINI_API_KEY",
    "GEMINI_PRIMARY_MODEL",
    "GEMINI_FALLBACK_MODEL",
    "GEMINI_TEXT_MODEL",
    "GEMINI_VISION_MODEL",
    "GROQ_API_KEY",
    "GROQ_TEXT_MODEL",
    "GROQ_VISION_MODEL",
    "GROQ_FALLBACK_MODEL",
    "encode_image_to_base64",
    "get_mime_type",
    "parse_json_response",
    "extract_json_object",
    "extract_json_array",
    "call_gemini",
    "call_gemini_json_object",
    "call_gemini_json_array",
    "call_gemini_chat",
    "call_groq",
    "call_groq_json_object",
    "call_groq_json_array",
    "call_groq_chat",
]
