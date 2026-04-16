import os
import json
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key or api_key == "YOUR_GEMINI_API_KEY_HERE":
    print("WARNING: GEMINI_API_KEY is not set correctly in .env file")

genai.configure(api_key=api_key)
model = genai.GenerativeModel("gemini-2.5-flash")

def analyze_resume(resume_text):
    prompt = f"""
    Analyze the following resume text and provide a JSON response with the following structure:
    {{
      "skills": ["skill1", "skill2"],
      "projects": ["project1", "project2"],
      "experience": ["exp1", "exp2"],
      "education": ["edu1"],
      "tools": ["tool1", "tool2"],
      "missing_skills_for_roles": ["skill1", "skill2"],
      "suggestions": ["suggestion1", "suggestion2"],
      "resume_score": 85,
      "career_roadmap": [
        {{"step": 1, "goal": "Learn X", "duration": "2 weeks"}},
        {{"step": 2, "goal": "Build Y", "duration": "4 weeks"}}
      ]
    }}
    Resume Text: {resume_text}
    """
    
    try:
        response = model.generate_content(prompt)
        
        # Check if response was blocked
        if not response.candidates:
            print(f"Gemini analysis blocked. Prompt feedback: {response.prompt_feedback}")
            raise Exception("AI response was blocked by safety filters. Please try again.")

        text = response.text
        # Clean potential markdown from response
        json_str = text.replace("```json", "").replace("```", "").strip()
        return json.loads(json_str)
    except Exception as e:
        print(f"Gemini analysis error: {str(e)}")
        # Pass the actual error message for better debugging
        raise Exception(f"AI Analysis failed: {str(e)}")

def chat_with_ai(user_message, history=None):
    if history is None:
        history = []
    
    # history in python SDK is a list of content objects
    # [{"role": "user", "parts": ["..."]}, {"role": "model", "parts": ["..."]}]
    chat = model.start_chat(history=history)
    
    try:
        response = chat.send_message(user_message)
        
        # Check if response was blocked
        if not response.candidates:
            print(f"Gemini chat blocked. Prompt feedback: {response.prompt_feedback}")
            return "I'm sorry, I cannot respond to that message due to safety filters."

        return response.text
    except Exception as e:
        print(f"Gemini chat error: {str(e)}")
        raise Exception(f"AI Assistant failed: {str(e)}")
