import OpenAI from "openai";
import dotenv from "dotenv";

// Load environment variables for local testing
dotenv.config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

async function testOpenAIConnection() {
  console.log("🧪 Testing OpenAI API Connection...\n");

  // Check if API key is configured
  if (!process.env.OPENAI_API_KEY) {
    console.error("❌ OPENAI_API_KEY environment variable is not set");
    console.log("💡 Please create a .env file with your OpenAI API key");
    process.exit(1);
  }

  try {
    console.log("🔑 API Key configured ✅");
    console.log("🤖 Testing with model: gpt-4o-mini");
    
    const startTime = Date.now();
    
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "You are Lemon, a helpful AI travel planner."
        },
        {
          role: "user",
          content: "Create a brief 2-day itinerary for Paris focusing on must-see attractions."
        }
      ],
      temperature: 0.7,
      max_tokens: 500,
      timeout: 30000
    });

    const endTime = Date.now();
    const responseTime = endTime - startTime;

    console.log(`⚡ Response Time: ${responseTime}ms`);
    console.log(`📊 Tokens Used: ${completion.usage?.total_tokens || 'N/A'}`);
    console.log(`💰 Cost Estimate: ~$${((completion.usage?.total_tokens || 0) * 0.0002).toFixed(4)}`);
    console.log("\n📝 Sample Response:");
    console.log("=" * 50);
    console.log(completion.choices[0].message.content);
    console.log("=" * 50);
    
    console.log("\n✅ OpenAI API is working correctly!");
    console.log("🚀 Your integration is ready for deployment to Vercel");

  } catch (error) {
    console.error("\n❌ OpenAI API Error:");
    
    if (error.status === 401) {
      console.error("🔐 Authentication Error: Invalid API key");
      console.log("💡 Check that your OPENAI_API_KEY is correct");
    } else if (error.status === 429) {
      console.error("⏰ Rate Limit Error: Too many requests");
      console.log("💡 Wait a moment and try again, or check your OpenAI quota");
    } else if (error.status === 404) {
      console.error("🚫 Model Not Found: The model may be deprecated");
      console.log("💡 Try updating to a newer model version");
    } else if (error.code === 'insufficient_quota') {
      console.error("💳 Quota Exceeded: Not enough credits");
      console.log("💡 Add credits to your OpenAI account");
    } else {
      console.error("🐛 Unexpected Error:", error.message);
    }
    
    process.exit(1);
  }
}

console.log("🍋 Lemon AI Travel Planner - API Test\n");
testOpenAIConnection(); 