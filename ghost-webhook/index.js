require("dotenv").config();
const express = require("express");
const axios = require("axios");

const app = express();
app.use(express.json());

app.post("/webhook", async (req, res) => {
  console.log("Received webhook from Ghost:", req.body);

  const GITHUB_PAT = process.env.GITHUB_PAT;
  const REPO = "florida/florida.github.io";
  const WORKFLOW = "deploy.yml";

  await new Promise((resolve) => setTimeout(resolve, 10000));

  try {
    const response = await axios.post(
      `https://api.github.com/repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches`,
      { ref: "main" },
      { headers: { Authorization: `token ${GITHUB_PAT}` } }
    );

    console.log("Triggered GitHub Action:", response.status);
    res.status(200).send("GitHub Action triggered!");
  } catch (error) {
    console.error(
      "Error triggering GitHub:",
      error.response?.data || error.message
    );
    res.status(500).send("Failed to trigger GitHub Action.");
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Listening on port ${PORT}`));
