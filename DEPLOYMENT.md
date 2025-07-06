# Deployment Guide for Alibi Middleware Server

This guide will help you deploy the Alibi Middleware Server to the internet so players worldwide can access your Roblox interrogation game.

## Option 1: Railway (Recommended - Free Tier)

Railway is the easiest and most cost-effective option for this project.

### Step 1: Prepare Your Code
1. Make sure all files are committed to a Git repository (GitHub, GitLab, etc.)
2. Ensure your `secrets/.env` file contains your OpenAI API key

### Step 2: Deploy to Railway
1. Go to [railway.app](https://railway.app) and sign up with GitHub
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your repository
4. Railway will automatically detect it's a Node.js project and deploy

### Step 3: Configure Environment Variables
1. In your Railway project dashboard, go to "Variables" tab
2. Add your environment variables:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   NODE_ENV=production
   ```

### Step 4: Get Your Deployment URL
1. Railway will provide a URL like: `https://your-app-name.railway.app`
2. Copy this URL for use in your Roblox script

### Step 5: Update Roblox Script
Replace the middleware URL in your Roblox script:
```lua
local MIDDLEWARE_URL = "https://your-app-name.railway.app"
```

## Option 2: Render (Alternative - Free Tier)

### Step 1: Prepare for Render
1. Create a `render.yaml` file in your project root:
```yaml
services:
  - type: web
    name: alibi-middleware
    env: node
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: OPENAI_API_KEY
        sync: false
```

### Step 2: Deploy to Render
1. Go to [render.com](https://render.com) and sign up
2. Click "New" → "Web Service"
3. Connect your GitHub repository
4. Configure environment variables
5. Deploy

## Option 3: Heroku (Paid Option)

### Step 1: Install Heroku CLI
```bash
# Download and install from https://devcenter.heroku.com/articles/heroku-cli
```

### Step 2: Deploy
```bash
heroku create your-app-name
git push heroku main
heroku config:set OPENAI_API_KEY=your_api_key
heroku config:set NODE_ENV=production
```

## Option 4: Vercel (Alternative)

### Step 1: Create vercel.json
```json
{
  "version": 2,
  "builds": [
    {
      "src": "index.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "index.js"
    }
  ]
}
```

### Step 2: Deploy
1. Install Vercel CLI: `npm i -g vercel`
2. Run: `vercel`
3. Configure environment variables in Vercel dashboard

## Testing Your Deployment

### Health Check
Test your deployment with:
```bash
curl https://your-app-name.railway.app/health
```

### Test Interrogation
```bash
curl -X POST https://your-app-name.railway.app/interrogate \
  -H "Content-Type: application/json" \
  -d '{
    "playerName": "TestPlayer",
    "role": "Driver",
    "difficulty": "Medium"
  }'
```

## Security Considerations

### Environment Variables
- Never commit API keys to your repository
- Use environment variables for all sensitive data
- Railway/Render/Heroku provide secure environment variable storage

### CORS Configuration
The server is configured to only allow requests from Roblox domains in production:
- `https://www.roblox.com`
- `https://web.roblox.com`

### Rate Limiting
The server includes rate limiting to prevent abuse:
- 100 requests per 15 minutes per IP
- Configurable in `config.js`

## Monitoring and Logs

### Railway
- View logs in the Railway dashboard
- Set up alerts for errors
- Monitor usage and performance

### Health Monitoring
The `/health` endpoint can be used for:
- Uptime monitoring services
- Load balancer health checks
- Automated testing

## Cost Considerations

### Railway
- Free tier: $5 credit monthly
- Pay-as-you-go after that
- Estimated cost: $2-5/month for moderate usage

### Render
- Free tier available
- Sleeps after 15 minutes of inactivity
- Paid plans start at $7/month

### Heroku
- No free tier anymore
- Basic dyno: $7/month
- Eco dyno: $5/month

## Troubleshooting

### Common Issues

1. **Environment Variables Not Set**
   - Check your deployment platform's environment variable settings
   - Ensure `OPENAI_API_KEY` is correctly set

2. **CORS Errors**
   - Verify the CORS configuration in `config.js`
   - Check that requests are coming from allowed origins

3. **Rate Limiting**
   - If you hit rate limits, increase limits in `config.js`
   - Consider implementing user-specific rate limiting

4. **OpenAI API Errors**
   - Check your OpenAI account balance
   - Verify API key permissions
   - Check rate limits on OpenAI side

### Debugging
- Check deployment logs for errors
- Use the `/health` endpoint to verify server status
- Test with curl before using in Roblox

## Performance Optimization

### For High Traffic
1. Increase rate limits in `config.js`
2. Consider using a CDN
3. Implement caching for common responses
4. Use a more powerful deployment plan

### Cost Optimization
1. Use faster OpenAI models for simple responses
2. Implement response caching
3. Monitor usage and adjust limits accordingly

## Next Steps

After deployment:
1. Test thoroughly with your Roblox game
2. Monitor performance and costs
3. Set up alerts for errors
4. Consider implementing analytics
5. Plan for scaling as your game grows 