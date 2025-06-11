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
    const {
      departure_city,
      destination_cities,
      daily_budget: rawDailyBudget,
      duration: rawDuration
    } = req.body;

    // Apply defaults for optional fields
    const daily_budget = typeof rawDailyBudget === "number" && rawDailyBudget > 0 ? rawDailyBudget : (parseFloat(rawDailyBudget) > 0 ? parseFloat(rawDailyBudget) : 1000);
    const parsedDuration = parseInt(rawDuration, 10);
    const duration = parsedDuration >= 1 && parsedDuration <= 99 ? parsedDuration : 17;

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

    // Helper: extract the ordered list of unique destination cities from the route (exclude departure city)
    const tokens = route.split("->").map((t) => t.trim());
    const orderedCities = [];
    for (let i = 0; i < tokens.length; i += 2) {
      const city = tokens[i];
      if (!city || city.toLowerCase() === departure_city.toLowerCase()) continue; // skip departure
      if (!orderedCities.includes(city)) orderedCities.push(city);
    }

    // Popularity heuristic (higher score = more popular)
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

    // Allocate days to each city based on popularity
    const baseDays = Math.floor(duration / orderedCities.length);
    let remaining = duration - baseDays * orderedCities.length;

    // Determine allocation order (most popular first)
    const citiesByPopularity = [...orderedCities].sort((a, b) => {
      const aScore = popularityScore[a.toLowerCase()] || 50;
      const bScore = popularityScore[b.toLowerCase()] || 50;
      return bScore - aScore;
    });

    const daysPerCity = {};
    orderedCities.forEach((city) => (daysPerCity[city] = baseDays));
    for (let i = 0; i < remaining; i++) {
      const city = citiesByPopularity[i % citiesByPopularity.length];
      daysPerCity[city] += 1;
    }

    // Ask OpenAI for hotel recommendations within the budget
    const hotelPrompt = `Recommend one highly-rated hotel under $${daily_budget} USD per night for each of the following cities: ${orderedCities.join(", ")}.\n\nRespond ONLY with valid JSON where each key is the city and the value is the hotel name. Do not include any additional text or formatting.`;

    let hotels = {};
    try {
      const hotelCompletion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "You are Lemon, a helpful AI travel planner." },
          { role: "user", content: hotelPrompt }
        ],
        temperature: 0.4
      });

      const rawJson = hotelCompletion.choices[0].message.content.trim();
      hotels = JSON.parse(rawJson);
    } catch (hotelErr) {
      console.error("Failed to fetch hotel recommendations", hotelErr);
    }

    const detailedStops = orderedCities.map((city) => ({
      name: city,
      days: daysPerCity[city],
      hotel: hotels[city] || null
    }));

    res.status(200).json({
      route,
      total_days: duration,
      daily_budget,
      stops: detailedStops
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to generate route" });
  }
} 