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

  const { messages, schema: clientSchema } = req.body;
  if (!Array.isArray(messages)) {
    return res.status(400).json({ error: "'messages' array is required in request body" });
  }

  // If no conversation yet, immediately ask first initial question without calling OpenAI
  if (messages.length === 0) {
    const schemaObj = clientSchema && typeof clientSchema === "object" ? clientSchema : collectorTool;
    if (schemaObj && schemaObj.parameters && Array.isArray(schemaObj.parameters.required)) {
      const firstKey = schemaObj.parameters.required[0];
      const prop = schemaObj.parameters.properties?.[firstKey];
      const initialQ = prop?.x_initial_question || `Please provide ${firstKey}.`;
      return res.status(200).json({ message: { role: "assistant", content: initialQ } });
    }
  }

  const systemMsg = {
    role: "system",
    content:
      "You are Lemon, a friendly AI travel agent. You have a function definition with custom metadata `x_initial_question` for each parameter. When any required field is missing, ask ONLY the question specified in that parameter's `x_initial_question`. Once all required fields are collected, call the function with complete arguments."
  };

  const openaiMessages = [systemMsg, ...messages];

  // Pick schema: client-supplied takes precedence if valid
  const schemaForCall = clientSchema && typeof clientSchema === "object" ? clientSchema : collectorTool;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: openaiMessages,
      tools: schemaForCall ? [{ type: "function", function: schemaForCall }] : undefined,
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