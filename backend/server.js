const express = require("express");
const cors = require("cors");
require("dotenv").config();

const resumeRoutes = require("./routes/resume");
const aiRoutes = require("./routes/ai");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/resume", resumeRoutes);
app.use("/api/ai", aiRoutes);

app.listen(5000, () => {
  console.log("Server running on port 5000");
});