const { GoogleGenerativeAI } = require("@google/generative-ai");
require("dotenv").config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

const analyzeResume = async (resumeText) => {
  const prompt = `
    Analyze the following resume text and provide a JSON response with the following structure:
    {
      "skills": ["skill1", "skill2"],
      "projects": ["project1", "project2"],
      "experience": ["exp1", "exp2"],
      "education": ["edu1"],
      "tools": ["tool1", "tool2"],
      "missing_skills_for_roles": ["skill1", "skill2"],
      "suggestions": ["suggestion1", "suggestion2"],
      "resume_score": 85,
      "career_roadmap": [
        {"step": 1, "goal": "Learn X", "duration": "2 weeks"},
        {"step": 2, "goal": "Build Y", "duration": "4 weeks"}
      ]
    }
    Resume Text: ${resumeText}
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    // Clean potential markdown from response
    const jsonStr = text.replace(/```json|```/g, "").trim();
    return JSON.parse(jsonStr);
  } catch (error) {
    console.error("Gemini analysis error:", error);
    throw new Error("Failed to analyze resume with AI");
  }
};

const chatWithAI = async (userMessage, history = []) => {
  const chat = model.startChat({
    history: history,
    generationConfig: {
      maxOutputTokens: 500,
    },
  });

  try {
    const result = await chat.sendMessage(userMessage);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error("Gemini chat error:", error);
    throw new Error("AI Assistant failed to respond");
  }
};

module.exports = { analyzeResume, chatWithAI };
