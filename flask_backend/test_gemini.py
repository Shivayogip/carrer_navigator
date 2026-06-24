import os
from google import genai
from dotenv import load_dotenv

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

try:
    print("Available Models:")
    for m in client.models.list():
        print(m.name)
except Exception as e:
    print("Error listing models:", e)

try:
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents="Say hello in one word",
    )
    print("Chat test SUCCESS:", response.text)
except Exception as e:
    print("Chat test ERROR:", e)
