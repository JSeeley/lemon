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

// Helper to generate a detailed plan with route, per-city days, and hotels
async function generatePlan(args) {
  const {
    destination_cities,
    departure_city,
    daily_budget: rawDailyBudget,
    duration: rawDuration
  } = args;

  if (!Array.isArray(destination_cities) || destination_cities.length === 0 || !departure_city) {
    throw new Error("Missing destination_cities or departure_city for route generation");
  }

  const daily_budget = typeof rawDailyBudget === "number" && rawDailyBudget > 0 ? rawDailyBudget : (parseFloat(rawDailyBudget) > 0 ? parseFloat(rawDailyBudget) : 1000);
  const parsedDuration = parseInt(rawDuration, 10);
  const duration = parsedDuration >= 1 && parsedDuration <= 99 ? parsedDuration : 17;

  const destList = destination_cities.join(", ");

  // 1) Get the efficient route string (same as before)
  const routePrompt = `A traveler is leaving from ${departure_city} and wants to visit the following cities: ${destList}.\n\nChoose the most time-efficient order to visit all cities and return to ${departure_city}. For every leg, recommend the main mode(s) of transportation followed by an approximate travel time.\n\nRespond with EXACTLY one line formatted like this (replace items in angle brackets):\n<City A> -> <Transport & ~duration> -> <City B> -> <Transport & ~duration> -> ... -> <City A>.\n\nDo not add any additional text, explanation, or formatting.`;

  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      { role: "system", content: "You are Lemon, a helpful AI travel planner." },
      { role: "user", content: routePrompt }
    ],
    temperature: 0.3
  });

  const route = completion.choices[0].message.content.trim();

  // Extract ordered unique destination cities (exclude departure city)
  const tokens = route.split("->").map((t) => t.trim());
  const orderedCities = [];
  for (let i = 0; i < tokens.length; i += 2) {
    const city = tokens[i];
    if (!city || city.toLowerCase() === departure_city.toLowerCase()) continue;
    if (!orderedCities.includes(city)) orderedCities.push(city);
  }

  // Popularity heuristic
  const popularityScore = {
    paris: 100,
    "new york": 99,
    tokyo: 98,
    london: 97,
    rome: 96,
    barcelona: 95,
    dubai: 94,
    singapore: 93,
    kyoto: 92,
    istanbul: 91
  };

  const baseDays = Math.floor(duration / orderedCities.length);
  let remaining = duration - baseDays * orderedCities.length;

  const citiesByPopularity = [...orderedCities].sort((a, b) => {
    const aScore = popularityScore[a.toLowerCase()] || 50;
    const bScore = popularityScore[b.toLowerCase()] || 50;
    return bScore - aScore;
  });

  const daysPerCity = {};
  orderedCities.forEach((city) => (daysPerCity[city] = baseDays));
  for (let i = 0; i < remaining; i++) {
    const c = citiesByPopularity[i % citiesByPopularity.length];
    daysPerCity[c] += 1;
  }

  // 2) Ask for hotels within budget
  let hotels = {};
  try {
    const hotelPrompt = `Recommend one highly-rated hotel under $${daily_budget} USD per night for each of the following cities: ${orderedCities.join(", ")}.\n\nRespond ONLY with valid JSON where each key is the city and the value is the hotel name. Do not include any additional text or formatting.`;

    const hotelComp = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are Lemon, a helpful AI travel planner." },
        { role: "user", content: hotelPrompt }
      ],
      temperature: 0.4
    });

    hotels = JSON.parse(hotelComp.choices[0].message.content.trim());
  } catch (err) {
    console.error("Hotel fetch failed", err);
  }

  const stops = orderedCities.map((city) => ({
    name: city,
    days: daysPerCity[city],
    hotel: hotels[city] || null
  }));

  return {
    route,
    total_days: duration,
    daily_budget,
    stops
  };
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

    let assistantMessage = completion.choices[0].message;

    // If the assistant is calling our function, handle it
    if (assistantMessage.tool_calls && assistantMessage.tool_calls.length > 0) {
      const call = assistantMessage.tool_calls[0];
      if (call.type === "function" && call.function?.name === "submit_trip_query") {
        try {
          const args = JSON.parse(call.function.arguments || "{}");
          const plan = await generatePlan(args);

          assistantMessage = {
            role: "assistant",
            content: JSON.stringify(plan)
          };
        } catch (fnErr) {
          console.error("Failed to run submit_trip_query", fnErr);
          assistantMessage = {
            role: "assistant",
            content: "Sorry, I encountered an error while generating your itinerary. Please try again."
          };
        }
      }
    }

    // Return the assistant message back to the client (itinerary or follow-up question)
    res.status(200).json({ message: assistantMessage });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to generate chat response" });
  }
} 