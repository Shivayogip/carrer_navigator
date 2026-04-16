const express = require("express");
const router = express.Router();
const multer = require("multer");
const extractText = require("../utils/parser");
const { analyzeResume } = require("../utils/ai_service");

const upload = multer();

router.post("/upload", upload.single("resume"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    console.log("File received:", req.file.originalname);

    // Extract text from resume
    const text = await extractText(req.file);

    // AI Analysis using Gemini
    const analysis = await analyzeResume(text);

    res.json(analysis);
  } catch (error) {
    console.error("Resume processing error:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;