import OpenAI from 'openai';
import Cors from 'cors';

// Initialize CORS middleware
const cors = Cors({
  methods: ['POST', 'GET', 'HEAD'],
});

// Helper method to wait for a middleware to execute before continuing
function runMiddleware(req, res, fn) {
  return new Promise((resolve, reject) => {
    fn(req, res, (result) => {
      if (result instanceof Error) {
        return reject(result);
      }
      return resolve(result);
    });
  });
}

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export default async function handler(req, res) {
  // Run the middleware
  await runMiddleware(req, res, cors);

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { destination, duration, preferences, budget } = req.body;

    if (!destination) {
      return res.status(400).json({ error: 'Destination is required' });
    }

    const prompt = `Create a detailed travel itinerary for a trip to ${destination}. 
    ${duration ? `Duration: ${duration}` : ''}
    ${preferences ? `Preferences: ${preferences}` : ''}
    ${budget ? `Budget: ${budget}` : ''}
    
    Please provide:
    1. Day-by-day itinerary with activities
    2. Recommended hotels/accommodations
    3. Must-try restaurants and local cuisine
    4. Transportation tips
    5. Budget breakdown
    6. Best time to visit and weather considerations
    
    Format the response in a clear, structured way that's easy to read.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are a professional travel planner who creates personalized, detailed itineraries. Be specific with recommendations and include practical tips."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.8,
      max_tokens: 2000,
    });

    const itinerary = completion.choices[0].message.content;

    res.status(200).json({
      success: true,
      destination,
      itinerary,
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error generating itinerary:', error);
    res.status(500).json({
      error: 'Failed to generate itinerary',
      details: error.message
    });
  }
}