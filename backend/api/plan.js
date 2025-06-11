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
    const { destination, startDate, endDate, travelers, preferences } = req.body;

    if (!destination || !startDate || !endDate) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    // Check if API key is configured
    if (!process.env.OPENAI_API_KEY) {
      console.error("OpenAI API key is not configured");
      return res.status(500).json({ error: "API configuration error" });
    }

    const prompt = `You are Lemon, an expert travel planner. Craft a detailed, day-by-day itinerary for a trip to ${destination} from ${startDate} to ${endDate}. Number of travelers: ${travelers ?? 1}. Preferences: ${preferences ?? "None specified"}. Include transportation, lodging, dining and activities.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini", // Using the latest, cost-effective model
      messages: [
        {
          role: "system",
          content: "You are Lemon, a helpful AI travel planner with expertise in creating detailed, personalized travel itineraries. Provide practical, well-structured travel plans with specific recommendations."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 2000, // Increased for more detailed itineraries
      timeout: 30000 // 30 second timeout to avoid Vercel function timeout
    });

    const itinerary = completion.choices[0].message.content;

    res.status(200).json({ 
      itinerary,
      model: "gpt-4o-mini",
      usage: completion.usage
    });
  } catch (err) {
    console.error("OpenAI API Error:", err);
    
    // Enhanced error handling for common OpenAI API issues
    if (err.status === 401) {
      return res.status(500).json({ error: "API authentication failed. Please check your API key." });
    } else if (err.status === 429) {
      return res.status(429).json({ error: "Rate limit exceeded. Please try again later." });
    } else if (err.status === 404) {
      return res.status(500).json({ error: "Model not found. The requested model may be deprecated." });
    } else if (err.code === 'context_length_exceeded') {
      return res.status(400).json({ error: "Request too long. Please provide shorter input." });
    } else if (err.code === 'insufficient_quota') {
      return res.status(429).json({ error: "API quota exceeded. Please check your OpenAI billing." });
    }
    
    res.status(500).json({ 
      error: "Failed to generate itinerary", 
      details: process.env.NODE_ENV === 'development' ? err.message : undefined 
    });
  }
} 