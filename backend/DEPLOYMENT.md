# Lemon AI Travel Planner - Deployment Guide

## Prerequisites

1. **OpenAI API Key**: Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. **Vercel Account**: Create account at [vercel.com](https://vercel.com)
3. **Node.js**: Version 18+ recommended

## Environment Variables Setup

### For Vercel Deployment:

1. Go to your Vercel project dashboard
2. Navigate to **Settings** → **Environment Variables**
3. Add the following variable:
   - **Name**: `OPENAI_API_KEY`
   - **Value**: Your OpenAI API key (starts with `sk-`)
   - **Environment**: Production, Preview, Development (select all)

### For Local Development:

1. Copy `dotenv-example.txt` to `.env`
2. Replace the placeholder with your actual API key:
   ```
   OPENAI_API_KEY="sk-your-actual-key-here"
   ```

## Deployment Steps

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Test Locally**:
   ```bash
   npm run dev
   ```

3. **Deploy to Vercel**:
   ```bash
   vercel --prod
   ```

## Current Configuration

- **Model**: `gpt-4o-mini` (Latest cost-effective model as of 2024-2025)
- **Max Tokens**: 2000 (Sufficient for detailed itineraries)
- **Timeout**: 30 seconds (Prevents Vercel timeout issues)
- **Temperature**: 0.7 (Good balance of creativity and consistency)

## Troubleshooting Common Issues

### 1. 401 Unauthorized Error
- **Cause**: Invalid or missing API key
- **Solution**: 
  - Verify your OpenAI API key is correct
  - Ensure environment variable is set in Vercel
  - Check API key has sufficient credits

### 2. 404 Model Not Found
- **Cause**: Using deprecated model
- **Solution**: Code updated to use `gpt-4o-mini` (current stable model)

### 3. 429 Rate Limit Error
- **Cause**: Too many requests or quota exceeded
- **Solution**: 
  - Wait before retrying
  - Check your OpenAI billing/quota
  - Consider upgrading your OpenAI plan

### 4. 500 API Configuration Error
- **Cause**: Missing OPENAI_API_KEY environment variable
- **Solution**: 
  - Add environment variable in Vercel dashboard
  - Redeploy after adding the variable

### 5. Function Timeout
- **Cause**: OpenAI API response taking too long
- **Solution**: 
  - Code includes 30-second timeout
  - Consider shorter prompts if issue persists

## Testing Your Deployment

Test your API endpoint with:

```bash
curl -X POST https://your-app.vercel.app/api/plan \
  -H "Content-Type: application/json" \
  -d '{
    "destination": "Tokyo",
    "startDate": "2024-06-01",
    "endDate": "2024-06-05",
    "travelers": 2,
    "preferences": "Culture and food"
  }'
```

## Model Information

### Current Model: gpt-4o-mini
- **Cost**: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- **Context**: 128K tokens
- **Best for**: Cost-effective, high-quality text generation
- **Speed**: Fast response times

### Alternative Models (if needed):
- `gpt-4o`: More capable but more expensive
- `gpt-4.1`: Latest model with enhanced capabilities
- `gpt-4.1-mini`: Newer mini version

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for all sensitive data
3. **Implement rate limiting** for production use
4. **Monitor API usage** to prevent unexpected costs

## Support

If you continue to experience issues:

1. Check [Vercel Function Logs](https://vercel.com/docs/functions/logs)
2. Review [OpenAI API Status](https://status.openai.com/)
3. Verify your [OpenAI API Usage](https://platform.openai.com/usage)
4. Check this deployment guide for common solutions 