import fs from "fs";
import path from "path";
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Load the JSON schema for the collector function once at cold start
const schemaPath = path.join(process.cwd(), "schemas", "submit_trip_query.json");
let collectorTool;
try {
  const schemaFile = fs.readFileSync(schemaPath, "utf-8");
  collectorTool = JSON.parse(schemaFile);
} catch (err) {
  console.error("Failed to load submit_trip_query schema", err);
  collectorTool = null;
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  const { messages } = req.body;
  if (!Array.isArray(messages)) {
    return res.status(400).json({ error: "'messages' array is required in request body" });
  }

  const systemMsg = {
    role: "system",
    content:
      "You are Lemon, a friendly AI travel agent. Ask follow-up questions until you have all required fields to call the function."
  };

  const openaiMessages = [systemMsg, ...messages];

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: openaiMessages,
      tools: collectorTool ? [{ type: "function", function: collectorTool }] : undefined,
      temperature: 0.7
    });

    // Return the entire assistant message back to the client
    const assistantMessage = completion.choices[0].message;
    res.status(200).json({ message: assistantMessage });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to generate chat response" });
  }
} 