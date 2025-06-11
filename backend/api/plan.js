import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  try {
    // Expecting a departure city and an array of destination cities that need to be visited
    const { departure_city, destination_cities } = req.body;

    if (!departure_city || !Array.isArray(destination_cities) || destination_cities.length === 0) {
      return res.status(400).json({ error: "'departure_city' and non-empty 'destination_cities' array are required" });
    }

    // Build a comma-separated list of destination cities for the prompt
    const destList = destination_cities.join(", ");

    /*
      Prompt goal:
      1. Determine the most efficient route starting and ending at the departure city (round-trip), visiting each destination once.
      2. For every leg, recommend the primary mode(s) of transportation and give a rough duration.
      3. Output ONLY a single line in the format:
         <Departure> -> <Transport + duration> -> <Next City> -> ... -> <Transport + duration> -> <Departure>

      The system and user messages below enforce this strict format so downstream UI can parse / render it easily.
    */

    const prompt = `A traveler is leaving from ${departure_city} and wants to visit the following cities: ${destList}.\n\nChoose the most time-efficient order to visit all cities and return to ${departure_city}. For every leg, recommend the main mode(s) of transportation followed by an approximate travel time.\n\nRespond with EXACTLY one line formatted like this (replace items in angle brackets):\n<City A> -> <Transport & ~duration> -> <City B> -> <Transport & ~duration> -> ... -> <City A>.\n\nDo not add any additional text, explanation, or formatting.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are Lemon, a helpful AI travel planner." },
        { role: "user", content: prompt }
      ],
      temperature: 0.3 // lower temperature for more deterministic formatting
    });

    const route = completion.choices[0].message.content.trim();

    res.status(200).json({ route });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to generate route" });
  }
} 