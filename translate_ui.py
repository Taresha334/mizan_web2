import json
import os
import time
from google import genai

# --- CONFIGURATION ---
GEMINI_API_KEY = "AIzaSyA3Zb49ZD4qlWSg6RjBA6cK6nLnTMjQ89w" 
SOURCE_FILE = 'lib/core/l10n/app_en.arb'
TARGET_LANGS = {
    'am': 'lib/core/l10n/app_am.arb',
    'ti': 'lib/core/l10n/app_ti.arb',
    'om': 'lib/core/l10n/app_om.arb',
    'so': 'lib/core/l10n/app_so.arb'
}

client = genai.Client(api_key=GEMINI_API_KEY)

def get_gemini_translation(text, target_lang_code):
    lang_map = {
        'am': 'Amharic',
        'ti': 'Tigrigna',
        'om': 'Afaan Oromoo',
        'so': 'Somali'
    }
    target_lang = lang_map.get(target_lang_code, target_lang_code)
    
    prompt = (
        f"Translate this UI string for an Ethiopian animal feed company to {target_lang}: '{text}'. "
        f"Return ONLY the translated text."
    )

    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt
        )
        return response.text.strip()
    except Exception as e:
        print(f"⚠️ Error: {e}")
        return None

def main():
    if not os.path.exists(SOURCE_FILE):
        print(f"❌ Error: {SOURCE_FILE} still not found! Check your folder structure.")
        return

    with open(SOURCE_FILE, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

    for lang_code, file_path in TARGET_LANGS.items():
        # Ensure the directory exists
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as f:
                try:
                    target_data = json.load(f)
                except:
                    target_data = {"@@locale": lang_code}
        else:
            target_data = {"@@locale": lang_code}

        updated = False
        for key, value in en_data.items():
            if not key.startswith('@') and key not in target_data:
                print(f"🌐 [{lang_code.upper()}] Translating '{key}'...")
                translated = get_gemini_translation(value, lang_code)
                if translated:
                    target_data[key] = translated
                    updated = True
                    time.sleep(0.5)

        if updated:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(dict(sorted(target_data.items())), f, ensure_ascii=False, indent=2)
            print(f"✅ Updated {file_path}")

    print("\n📦 Running flutter gen-l10n...")
    os.system('flutter gen-l10n')

if __name__ == "__main__":
    main()