import os
import json
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key or api_key == "YOUR_GEMINI_API_KEY_HERE":
    print("WARNING: GEMINI_API_KEY is not set correctly in .env file")

client = genai.Client(api_key=api_key)
MODEL = "gemini-2.0-flash"

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
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
        )

        if not response.candidates:
            raise Exception("AI response was blocked by safety filters. Please try again.")

        text = response.text
        # Clean potential markdown from response
        json_str = text.replace("```json", "").replace("```", "").strip()
        return json.loads(json_str)
    except Exception as e:
        print(f"Gemini analysis error: {str(e)}")
        raise Exception(f"AI Analysis failed: {str(e)}")


def chat_with_ai(user_message, history=None):
    if history is None:
        history = []

    # Build contents list from history + new message
    contents = []
    for h in history:
        role = h.get("role", "user")
        parts = h.get("parts", [])
        if isinstance(parts, list):
            text = " ".join(parts)
        else:
            text = str(parts)
        contents.append(types.Content(role=role, parts=[types.Part(text=text)]))

    # Add current user message
    contents.append(types.Content(role="user", parts=[types.Part(text=user_message)]))

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=contents,
        )

        if not response.candidates:
            print(f"Gemini chat blocked. Prompt feedback: {response.prompt_feedback}")
            return "I'm sorry, I cannot respond to that message due to safety filters."

        return response.text
    except Exception as e:
        print(f"Gemini chat error: {str(e)}")
        raise Exception(f"AI Assistant failed: {str(e)}")


def analyze_github_profile(username, repos, events, target_role=None):
    context = f"Username: {username}\n"
    context += f"Target Role: {target_role if target_role else 'Full Stack Developer'}\n\n"

    context += "Top Repositories:\n"
    for repo in repos[:10]:  # Analyze top 10
        context += f"- {repo.get('name')}: {repo.get('description')} (Language: {repo.get('language')}, Stars: {repo.get('stargazers_count')})\n"

    context += "\nRecent Activity Highlights:\n"
    for event in events[:15]:
        context += f"- {event.get('type')} at {event.get('repo', {}).get('name')} ({event.get('created_at')})\n"

    prompt = f"""
    You are an expert technical recruiter and open-source evaluator.
    Analyze the following GitHub profile data for the developer '{username}' in the context of their target job as '{target_role}'.
    
    Provide a professional but encouraging 4-section report in Markdown:
    1. **Profile Summary**: A brief overview of who they are as a developer.
    2. **Active Days & Consistency**: Analyze their recent commit events. Are they consistent? Do they contribute regularly?
    3. **Top Project Analysis**: Highlight 2-3 standout repositories and what they reveal about their skills.
    4. **Value Add for Target Job**: Specifically explain why this profile would impress a recruiter looking for a '{target_role}'.
    
    GitHub Context:
    {context}
    """

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
        )
        if not response.candidates:
            raise Exception("AI response was blocked by safety filters.")
        return response.text
    except Exception as e:
        print(f"Gemini GitHub Analysis error: {str(e)}")
        raise Exception(f"GitHub Analysis failed: {str(e)}")
