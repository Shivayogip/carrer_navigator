const express = require("express");
const router = express.Router();
const multer = require("multer");

const upload = multer();

router.post("/upload", upload.single("resume"), (req, res) => {
  console.log("File received:", req.file.originalname);

  // 🔥 TEMP DUMMY RESPONSE
  res.json({
    skills: ["Python", "React", "Git"],
    projects: ["AI Chatbot", "E-commerce App"],
    experience: ["Intern at ABC"],
    education: ["B.Tech CSE"],
    tools: ["Docker", "VS Code"],
    missing_skills_for_roles: ["System Design", "Cloud"],
    suggestions: [
      "Add more measurable achievements",
      "Improve formatting",
      "Add GitHub links"
    ]
  });
});

module.exports = router;