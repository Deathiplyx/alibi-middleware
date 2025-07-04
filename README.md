# Alibi Interrogation Middleware Server

A Node.js middleware server that acts as a secure relay between Roblox and OpenAI GPT API for an AI-driven interrogation game.

## Features

- 🤖 AI-powered detective interrogation using GPT-4
- 🎮 Dynamic scenario generation with realistic crime scenarios
- 📊 Evidence scaling based on difficulty levels
- 🕵️ Advanced lie detection and contradiction analysis
- ⏱️ Dual timer system (main interrogation + response timer)
- 🌐 Network-accessible for multiplayer games
- 🔧 **NEW: Middleware Diagnostic Tool** for testing and debugging
- ✅ **NEW: Enhanced validation** with detailed error messages
- 📝 **NEW: Comprehensive logging** for debugging

## Setup Instructions

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure OpenAI API
1. Create a `secrets` folder in the project root
2. Create a `.env` file inside the `secrets` folder
3. Add your OpenAI API key:
```
OPENAI_API_KEY=your_openai_api_key_here
```

### 3. Configure Network Settings
1. Run the IP finder script:
```bash
node find-ip.js
```

2. Update `config.js` with your network IP address:
```javascript
NETWORK_IP: '192.168.254.3', // Replace with your actual IP
```

3. Update your Roblox script with the same IP:
```lua
local MIDDLEWARE_URL = "http://192.168.254.3:3000"
```

### 4. Configure Firewall
Make sure your Windows Firewall allows incoming connections on port 3000:
1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Click "Change settings" and "Allow another app"
4. Browse to your Node.js installation and add it
5. Make sure both Private and Public are checked

### 5. Start the Server
```bash
npm start
```

## Usage

### For Local Development
- Use `localhost:3000` in your Roblox script
- Only works on your computer

### For Network Play (Other Players)
- Use your network IP (e.g., `192.168.254.3:3000`) in your Roblox script
- Other players on the same network can connect
- Make sure firewall allows connections

### For Internet Play
- Deploy to a cloud service (Heroku, Railway, etc.)
- Use the public URL in your Roblox script
- Update CORS settings in `config.js` if needed

## API Endpoints

### POST /interrogate
Main interrogation endpoint. Sends player responses to AI and returns detective questions.

**Request Body:**
```json
{
  "playerName": "PlayerName",
  "role": "Driver",
  "difficulty": "Medium",
  "evidenceList": ["Evidence 1", "Evidence 2"],
  "playerResponse": "Player's response",
  "conversationHistory": [
    {"role": "detective", "content": "Question"},
    {"role": "player", "content": "Answer"}
  ]
}
```

**Response:**
```json
{
  "response": "Detective's question/response",
  "scenario": {
    "crime": "Bank Vault Heist",
    "location": "Central Bank downtown",
    "time": "11:30 PM",
    "method": "Drilled through the back wall"
  },
  "evidence": ["Evidence 1", "Evidence 2"],
  "difficulty": "Medium",
  "timestamp": "2025-07-04T10:36:44.936Z"
}
```

### POST /interrogate (Diagnostic Mode)
**NEW:** Send `{diagnostic: true}` to test the endpoint and get configuration information.

**Request Body:**
```json
{
  "diagnostic": true
}
```

**Response:**
```json
{
  "ok": true,
  "message": "Diagnostic endpoint reached.",
  "expectedFields": [
    "playerName",
    "role",
    "difficulty",
    "evidenceList",
    "playerResponse",
    "conversationHistory",
    "sessionId"
  ],
  "validDifficulties": ["Easy", "Medium", "Hard", "Expert"],
  "validRoles": ["Driver", "Lookout", "Hacker", "Muscle", "Inside Man", "Mastermind", "Tech Specialist", "Demolitions Expert"]
}
```

### GET /health
Health check endpoint to verify server status.

## Middleware Diagnostic Tool

**NEW:** The server now includes a diagnostic tool for testing and debugging:

### Features:
- **Endpoint Testing**: Send `{diagnostic: true}` to test connectivity
- **Configuration Validation**: Checks for common setup issues
- **Field Validation**: Validates all required fields and their formats
- **Proxy Detection**: Warns about trust proxy configuration issues
- **Detailed Error Messages**: Shows exactly what's wrong and how to fix it

### Usage:
1. **From Roblox**: Use the diagnostic tool in your Roblox game
2. **From Browser**: Send POST request to `/interrogate` with `{diagnostic: true}`
3. **From Terminal**: Use curl or Postman to test the endpoint

### Valid Values:
- **Difficulties**: `Easy`, `Medium`, `Hard`, `Expert`
- **Roles**: `Driver`, `Lookout`, `Hacker`, `Muscle`, `Inside Man`, `Mastermind`, `Tech Specialist`, `Demolitions Expert`

## Configuration

Edit `config.js` to customize:
- Server port and host
- Network IP addresses
- OpenAI model settings
- Game timing settings
- CORS settings

## Deployment

### Local Development
```bash
npm start
```

### Production Deployment
1. **Railway**: Use the provided `railway.json` and `Procfile`
2. **Heroku**: Add a `Procfile` with `web: node index.js`
3. **Render**: Connect your GitHub repository and set environment variables
4. **Vercel**: Deploy as a Node.js function

### Environment Variables
- `OPENAI_API_KEY`: Your OpenAI API key
- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Set to `production` for production deployments

## Troubleshooting

### Connection Issues
1. Check if server is running: `curl http://localhost:3000/health`
2. Verify IP address: `node find-ip.js`
3. Check firewall settings
4. Ensure Roblox script uses correct URL

### Validation Errors
**NEW:** The server now provides detailed validation errors:

```json
{
  "error": "Validation failed",
  "details": ["difficulty must be one of: Easy, Medium, Hard, Expert"],
  "validDifficulties": ["Easy", "Medium", "Hard", "Expert"],
  "validRoles": ["Driver", "Lookout", "Hacker", ...]
}
```

### Common Issues:
1. **Invalid Difficulty**: Must be exactly `Easy`, `Medium`, `Hard`, or `Expert`
2. **Invalid Role**: Must be one of the valid roles listed above
3. **Empty Fields**: All required fields must be non-empty strings
4. **Whitespace Issues**: Fields are automatically trimmed

### OpenAI API Issues
1. Verify API key in `secrets/.env`
2. Check OpenAI account balance
3. Ensure API key has proper permissions

### Performance Issues
1. Reduce `OPENAI_MAX_TOKENS` in config
2. Increase `OPENAI_TEMPERATURE` for faster responses
3. Consider using a faster OpenAI model

### Proxy Issues
If you see "X-Forwarded-For header" warnings:
1. The server automatically sets `trust proxy` to `true`
2. This is handled automatically for most deployment platforms
3. No manual configuration needed

## Logging

**NEW:** Enhanced logging for debugging:

- **Request Logging**: All incoming requests are logged with headers and body
- **Success Logging**: Successful processing is logged with key details
- **Error Logging**: Detailed error messages with context
- **Validation Logging**: Failed validations are logged with details

Check your server console for detailed logs when troubleshooting.

## Security Notes

- Keep your OpenAI API key secure
- Don't commit `secrets/.env` to version control
- Consider rate limiting for production use
- Update CORS settings for production deployment
- **NEW:** Input validation prevents malicious payloads
- **NEW:** Trust proxy is automatically configured for security

## License

This project is for educational and entertainment purposes. 