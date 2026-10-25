import os
import requests
import json
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GROQ_API_KEY")
if not api_key:
    print("[Error] GEMINI_API_KEY not found in .env file.")
    exit(1)

url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
r = requests.get(url)

if r.status_code != 200:
    print(f"[Error] Failed to fetch Gemini models ({r.status_code}): {r.text[:200]}")
    exit(1)

data = r.json()
raw_models = data.get('models', [])
models = [m for m in raw_models if 'generateContent' in m.get('supportedGenerationMethods', [])]

print(f"Total: {len(models)} generateContent models available on Google Gemini:\n")
for m in models:
    mid = m.get('name', '').replace('models/', '')
    disp = m.get('displayName', '')
    in_tok = m.get('inputTokenLimit', '?')
    out_tok = m.get('outputTokenLimit', '?')
    print(f"  {mid:<36} | {disp:<32} | in_ctx={str(in_tok):<8} | out_ctx={out_tok}")

print("\n🚀 Fastest Recommended Model for AgriShield: gemini-2.5-flash-lite")
