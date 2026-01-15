import asyncio
import sys

async def check_ollama():
    print("Checking for 'ollama' Python package...")
    try:
        import ollama
        print("SUCCESS: 'ollama' package is installed.")
    except ImportError:
        print("ERROR: 'ollama' package NOT found. Please run: pip install ollama")
        return

    print("\nConnecting to local Ollama server...")
    try:
        client = ollama.AsyncClient()
        # Get list of local models
        models_response = await client.list()
        # Newer versions of ollama return objects, older return dicts
        models_data = models_response.get('models', [])
        models = [m.get('name', str(m)) for m in models_data]
        
        print(f"SUCCESS: Connected to Ollama. Found models: {models}")
        
        has_llama = any('llama3' in str(m).lower() for m in models)
        if has_llama:
            print("SUCCESS: 'llama3' model found!")
        else:
            print("WARNING: 'llama3' not found. You might need to run: ollama pull llama3")
            
        print("\nTesting simple chat...")
        response = await client.chat(model='llama3', messages=[{'role': 'user', 'content': 'Say hello in one word!'}])
        print(f"AI Response: {response['message']['content']}")
        print("\nSUCCESS: Verification complete!")
        
    except Exception as e:
        print(f"ERROR connecting to Ollama: {e}")
        print("Ensure the Ollama application is running on your machine and you have run 'ollama pull llama3'.")

if __name__ == "__main__":
    asyncio.run(check_ollama())
