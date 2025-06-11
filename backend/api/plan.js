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

    const prompt = `You are Lemon, an expert travel planner. Craft a detailed, day-by-day itinerary for a trip to ${destination} from ${startDate} to ${endDate}. Number of travelers: ${travelers ?? 1}. Preferences: ${preferences ?? "None specified"}. Include transportation, lodging, dining and activities.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo-0125",
      messages: [
        {
          role: "system",
          content: "You are Lemon, a helpful AI travel planner."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.7
    });

    const itinerary = completion.choices[0].message.content;

    res.status(200).json({ itinerary });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to generate itinerary" });
  }
} 