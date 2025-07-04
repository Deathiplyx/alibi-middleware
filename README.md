# Alibi Interrogation Middleware Server

A Node.js middleware server that acts as a secure relay between Roblox and OpenAI GPT API for an AI-driven interrogation game.

## Features

- 🤖 AI-powered detective interrogation using GPT-4
- 🎮 Dynamic scenario generation with realistic crime scenarios
- 📊 Evidence scaling based on difficulty levels
- 🕵️ Advanced lie detection and contradiction analysis
- ⏱️ Dual timer system (main interrogation + response timer)
- 🌐 Network-accessible for multiplayer games

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

### GET /health
Health check endpoint to verify server status.

## Configuration

Edit `config.js` to customize:
- Server port and host
- Network IP addresses
- OpenAI model settings
- Game timing settings
- CORS settings

## Troubleshooting

### Connection Issues
1. Check if server is running: `curl http://localhost:3000/health`
2. Verify IP address: `node find-ip.js`
3. Check firewall settings
4. Ensure Roblox script uses correct URL

### OpenAI API Issues
1. Verify API key in `secrets/.env`
2. Check OpenAI account balance
3. Ensure API key has proper permissions

### Performance Issues
1. Reduce `OPENAI_MAX_TOKENS` in config
2. Increase `OPENAI_TEMPERATURE` for faster responses
3. Consider using a faster OpenAI model

## Security Notes

- Keep your OpenAI API key secure
- Don't commit `secrets/.env` to version control
- Consider rate limiting for production use
- Update CORS settings for production deployment

## License

This project is for educational and entertainment purposes. 