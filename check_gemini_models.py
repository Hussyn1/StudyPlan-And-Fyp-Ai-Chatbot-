import google.generativeai as genai
import os
from dotenv import load_dotenv

def check_models():
    # Load .env from backend directory
    load_dotenv("backend/.env")
    
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("❌ Error: GEMINI_API_KEY not found in backend/.env file.")
        return

    print(f"Checking models for API Key: {api_key[:10]}...")
    
    try:
        genai.configure(api_key=api_key)
        
        print("\nAvailable models that support 'generateContent':")
        print("-" * 50)
        
        found_flash = False
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(f"✅ {m.name}")
                if "gemini-1.5-flash" in m.name:
                    found_flash = True
        
        print("-" * 50)
        
        if found_flash:
            print("\nRESULT: 'gemini-1.5-flash' is available for your key.")
        else:
            print("\n⚠️ WARNING: 'gemini-1.5-flash' was not found in the list.")
            print("Please see the list above for a model to use.")

    except Exception as e:
        print(f"\n❌ Error connecting to Gemini API: {e}")

if __name__ == "__main__":
    check_models()
