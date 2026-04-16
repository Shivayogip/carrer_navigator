const express = require("express");
const router = express.Router();
const { chatWithAI } = require("../utils/ai_service");

router.post("/chat", async (req, res) => {
  const { message, history } = req.body;

  if (!message) {
    return res.status(400).json({ error: "Message is required" });
  }

  try {
    const aiResponse = await chatWithAI(message, history);
    res.json({ response: aiResponse });
  } catch (error) {
    console.error("AI Assistant error:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
