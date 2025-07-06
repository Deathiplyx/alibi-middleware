const express = require('express');
const axios = require('axios');
const cors = require('cors');
const path = require('path');
const rateLimit = require('express-rate-limit');
const config = require('./config');
require('dotenv').config({ path: path.join(__dirname, 'secrets', '.env') });

const app = express();
const PORT = config.PORT;

// Session store for maintaining scenario state
const sessions = {};

// Session cleanup function (runs every 30 minutes)
function cleanupSessions() {
    const now = Date.now();
    const sessionTimeout = 30 * 60 * 1000; // 30 minutes
    
    Object.keys(sessions).forEach(playerName => {
        if (now - sessions[playerName].timestamp > sessionTimeout) {
            delete sessions[playerName];
            console.log(`🧹 Cleaned up expired session for ${playerName}`);
        }
    });
}

// Run cleanup every 30 minutes
setInterval(cleanupSessions, 30 * 60 * 1000);

// Set trust proxy for proxy support (add near the top, after app is created)
app.set('trust proxy', true);

// Rate limiting
const limiter = rateLimit({
    windowMs: config.RATE_LIMIT_WINDOW,
    max: config.RATE_LIMIT_MAX_REQUESTS,
    message: {
        error: 'Too many requests from this IP, please try again later.',
        retryAfter: Math.ceil(config.RATE_LIMIT_WINDOW / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Middleware
app.use(cors({
    origin: config.CORS_ORIGIN,
    credentials: true
}));
app.use(express.json());
app.use(limiter);

// OpenAI API configuration
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';

// Validate API key on startup
if (!OPENAI_API_KEY) {
    console.error('❌ OPENAI_API_KEY not found in secrets/.env');
    console.error('Please add your OpenAI API key to secrets/.env');
    process.exit(1);
}

console.log('✅ OpenAI API key loaded successfully');

// Dynamic scenario generation - Grounded in reality with logical crime-location pairs
const crimeLocationPairs = [
    { crime: "Bank Vault Heist", location: "Central Bank downtown" },
    { crime: "Jewelry Store Robbery", location: "Diamond District" },
    { crime: "Art Museum Theft", location: "Modern Art Gallery" },
    { crime: "Casino Cash Grab", location: "Royal Casino" },
    { crime: "Tech Company Break-in", location: "Silicon Valley Tech Campus" },
    { crime: "Pharmaceutical Warehouse Raid", location: "Downtown Medical District" },
    { crime: "Auction House Theft", location: "High-End Auction House" },
    { crime: "Diamond Exchange Robbery", location: "International Diamond Exchange" },
    { crime: "Armored Truck Heist", location: "Fort Knox Military Base" },
    { crime: "ATM Robbery", location: "Local Credit Union" },
    { crime: "Safe Deposit Box Theft", location: "Central Bank downtown" },
    { crime: "Cash Register Robbery", location: "Shopping Mall" },
    { crime: "Gas Station Robbery", location: "Gas Station" }
];

const methods = [
    "Drilled through the back wall", "Used explosives on the front door", "Cut through the skylight",
    "Hacked the security system", "Used crowbars to break in", "Deployed sleeping gas",
    "Used angle grinders to cut through metal", "Employed diamond-tipped drills", "Used lockpicking tools",
    "Deployed smoke bombs to disable cameras", "Used sledgehammers to break windows", "Used bolt cutters on locks"
];

const roles = ['Driver', 'Lookout', 'Hacker', 'Muscle', 'Inside Man', 'Mastermind', 'Tech Specialist', 'Demolitions Expert'];
const difficulties = ['Easy', 'Medium', 'Hard', 'Expert'];

// Generate random time between 10 PM and 4 AM
function generateRandomTime() {
    const hour = Math.floor(Math.random() * 6) + 22; // 22-27 (10 PM - 3 AM)
    const minute = Math.floor(Math.random() * 60);
    const ampm = hour >= 24 ? 'AM' : 'PM';
    const displayHour = hour >= 24 ? hour - 24 : hour;
    return `${displayHour}:${minute.toString().padStart(2, '0')} ${ampm}`;
}

// Generate evidence based on difficulty
function generateEvidence(scenario, playerName, difficulty) {
    const baseEvidence = [
        `${playerName}'s phone pinged near ${scenario.location} at ${scenario.time}`,
        `Security cameras captured suspicious activity at ${scenario.time}`,
        `A witness reported seeing a suspicious vehicle near the scene`
    ];
    
    const difficultyEvidence = {
        Easy: [
            `${playerName} was seen in the area earlier that day`,
            `A red car matching ${playerName}'s description was spotted`
        ],
        Medium: [
            `${playerName}'s fingerprints were found on the getaway vehicle`,
            `Cell tower data places ${playerName} at the scene`,
            `A neighbor reported seeing ${playerName} leave their house at ${scenario.time}`,
            `Security footage shows someone matching ${playerName}'s build entering the building`
        ],
        Hard: [
            `${playerName}'s DNA was found on a tool left at the scene`,
            `Bank records show ${playerName} withdrew $5000 the day before`,
            `A burner phone registered to ${playerName}'s address was used to coordinate`,
            `GPS data from ${playerName}'s car shows it was parked near the scene`,
            `A witness identified ${playerName} from a photo lineup`,
            `Forensic analysis links ${playerName} to the ${scenario.method}`
        ],
        Expert: [
            `${playerName}'s laptop contains detailed plans of the ${scenario.location}`,
            `A hidden camera in ${playerName}'s home shows them practicing the ${scenario.method}`,
            `Financial records show ${playerName} purchased specialized equipment`,
            `A co-conspirator has already confessed and implicated ${playerName}`,
            `Satellite imagery shows ${playerName}'s exact movements that night`,
            `A recording of ${playerName} discussing the plan was found`,
            `Forensic timeline analysis proves ${playerName} was at the scene`,
            `A coded message in ${playerName}'s phone directly references the crime`
        ]
    };
    
    const allEvidence = [...baseEvidence, ...difficultyEvidence[difficulty]];
    const evidenceCount = Math.min(allEvidence.length, 3 + (difficulties.indexOf(difficulty) * 2));
    
    // Shuffle and select random evidence
    return allEvidence.sort(() => Math.random() - 0.5).slice(0, evidenceCount);
}

// Generate dynamic scenario with logical crime-location pairs
function generateScenario() {
    const pair = crimeLocationPairs[Math.floor(Math.random() * crimeLocationPairs.length)];
    const method = methods[Math.floor(Math.random() * methods.length)];
    const time = generateRandomTime();
    
    return {
        crime: pair.crime,
        location: pair.location,
        time: time,
        method: method
    };
}

// POST /interrogate endpoint
app.post('/interrogate', async (req, res) => {
    // Log incoming request for debugging
    console.log('📥 Received /interrogate request:', {
        body: req.body,
        headers: {
            'content-type': req.headers['content-type'],
            'user-agent': req.headers['user-agent']
        }
    });

    // Diagnostic handler
    if (req.body && req.body.diagnostic === true) {
        // Warn if trust proxy is not set and X-Forwarded-For is present
        if (!app.get('trust proxy') && req.headers['x-forwarded-for']) {
            return res.json({
                ok: false,
                message: "X-Forwarded-For header is set but the Express 'trust proxy' setting is false. Set app.set('trust proxy', true) in your Express app.",
                expectedFields: [
                    "playerName",
                    "role", 
                    "difficulty",
                    "evidenceList",
                    "playerResponse",
                    "conversationHistory",
                    "sessionId"
                ],
                validDifficulties: difficulties,
                validRoles: roles
            });
        }
        return res.json({
            ok: true,
            message: "Diagnostic endpoint reached.",
            expectedFields: [
                "playerName",
                "role",
                "difficulty", 
                "evidenceList",
                "playerResponse",
                "conversationHistory",
                "sessionId"
            ],
            validDifficulties: difficulties,
            validRoles: roles
        });
    }

    try {
        const { playerName, role, difficulty, evidenceList, playerResponse, playerAnswer, conversationHistory, history, context, startInterrogation } = req.body;
        
        // Handle different field names from different clients
        const actualPlayerResponse = playerResponse || playerAnswer || '';
        const actualConversationHistory = conversationHistory || history || [];
        const isFirstMessage = startInterrogation === true || !actualConversationHistory || actualConversationHistory.length === 0;

        // Enhanced validation with better error messages
        const validationErrors = [];
        
        if (!playerName || typeof playerName !== 'string' || playerName.trim() === '') {
            validationErrors.push('playerName must be a non-empty string');
        }
        
        if (!role || typeof role !== 'string' || role.trim() === '') {
            validationErrors.push('role must be a non-empty string');
        } else if (!roles.includes(role)) {
            validationErrors.push(`role must be one of: ${roles.join(', ')}`);
        }
        
        if (!difficulty || typeof difficulty !== 'string' || difficulty.trim() === '') {
            validationErrors.push('difficulty must be a non-empty string');
        } else if (!difficulties.includes(difficulty)) {
            validationErrors.push(`difficulty must be one of: ${difficulties.join(', ')}`);
        }

        if (validationErrors.length > 0) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validationErrors,
                validDifficulties: difficulties,
                validRoles: roles
            });
        }

        // Clean up the input values
        const cleanPlayerName = playerName.trim();
        const cleanRole = role.trim();
        const cleanDifficulty = difficulty.trim();

        // Session management - check if this is a new interrogation or continuation
        let scenario = null;
        let generatedEvidence = [];
        
        if (isFirstMessage) {
            // Start new session
            scenario = generateScenario();
            generatedEvidence = generateEvidence(scenario, cleanPlayerName, cleanDifficulty);
            
            // Store session data
            sessions[cleanPlayerName] = {
                scenario: scenario,
                evidence: generatedEvidence,
                history: [],
                timestamp: Date.now()
            };
            
            console.log(`🆕 Started new session for ${cleanPlayerName}:`, {
                crime: scenario.crime,
                location: scenario.location,
                time: scenario.time
            });
        } else {
            // Retrieve existing session
            const session = sessions[cleanPlayerName];
            if (!session) {
                console.log(`❌ Session not found for ${cleanPlayerName}`);
                return res.status(400).json({
                    error: 'Session not found. Please start a new interrogation.',
                    details: 'No active session found for this player'
                });
            }
            
            scenario = session.scenario;
            generatedEvidence = session.evidence;
            
            // Update session history
            session.history.push({
                question: actualConversationHistory[actualConversationHistory.length - 1]?.content || 'Previous question',
                answer: actualPlayerResponse
            });
            
            console.log(`🔄 Continuing session for ${cleanPlayerName}:`, {
                crime: scenario.crime,
                location: scenario.location,
                historyLength: session.history.length
            });
        }

        // Use provided evidence list or generated evidence
        const finalEvidenceList = evidenceList || generatedEvidence;

        // Build the prompt based on whether it's the first message or continuation
        let systemPrompt, userPrompt;

        if (isFirstMessage) {
            systemPrompt = `You are Detective Holloway, a seasoned investigator known for your sharp instincts and ability to spot lies. You are interrogating ${cleanPlayerName}, who is suspected of being the ${cleanRole} in a ${scenario.crime} at ${scenario.location}.

DIFFICULTY LEVEL: ${cleanDifficulty}
- Easy: Basic evidence, be patient and give them chances to explain
- Medium: Moderate evidence, be more persistent and look for gaps
- Hard: Strong evidence, be aggressive and confront contradictions directly
- Expert: Overwhelming evidence, be relentless and trap them in their lies

Your interrogation style:
- Be professional but firm, matching the difficulty level
- Ask specific questions about timing, location, and actions
- Look for contradictions in their story
- Use the evidence against them strategically
- Don't let them off easy - push for details
- If they're lying, call them out on inconsistencies
- Keep track of what they've said and compare it to evidence
- Build a case by gathering more information with each question
- REJECT any supernatural, fictional, or impossible explanations (aliens, superpowers, time travel, etc.)
- Focus only on real-world possibilities and evidence
- If they mention impossible things, call them out and demand realistic answers

The crime: ${scenario.crime} at ${scenario.location} at ${scenario.time}. The perpetrators ${scenario.method}.

Evidence against ${cleanPlayerName}:
${finalEvidenceList.map(evidence => `- ${evidence}`).join('\n')}

Start your interrogation. Ask your first question. Be direct and professional, matching the ${cleanDifficulty} difficulty level.`;

            userPrompt = "Begin the interrogation with your first question.";
        } else {
            // Continue the conversation with lie detection and evidence comparison
            systemPrompt = `You are Detective Holloway continuing your interrogation of ${cleanPlayerName}, the suspected ${cleanRole} in a ${scenario.crime}.

DIFFICULTY LEVEL: ${cleanDifficulty}
- Easy: Basic evidence, be patient and give them chances to explain
- Medium: Moderate evidence, be more persistent and look for gaps  
- Hard: Strong evidence, be aggressive and confront contradictions directly
- Expert: Overwhelming evidence, be relentless and trap them in their lies

Your interrogation style:
- Be professional but firm, matching the difficulty level
- Ask specific questions about timing, location, and actions
- Look for contradictions in their story
- Use the evidence against them strategically
- Don't let them off easy - push for details
- If they're lying, call them out on inconsistencies
- Keep track of what they've said and compare it to evidence
- Build a case by gathering more information with each question
- REJECT any supernatural, fictional, or impossible explanations (aliens, superpowers, time travel, etc.)
- Focus only on real-world possibilities and evidence
- If they mention impossible things, call them out and demand realistic answers

The crime: ${scenario.crime} at ${scenario.location} at ${scenario.time}. The perpetrators ${scenario.method}.

Evidence against ${cleanPlayerName}:
${finalEvidenceList.map(evidence => `- ${evidence}`).join('\n')}

Previous conversation context:
${actualConversationHistory.map(msg => `${msg.role === 'detective' ? 'Detective' : cleanPlayerName}: ${msg.content}`).join('\n')}

ANALYZE their latest response: "${actualPlayerResponse}"

Compare what they just said to:
1. The evidence we have
2. What they've said before
3. The known facts about the crime

If you find contradictions, lies, or inconsistencies, confront them directly. If they're being evasive, push harder. If they provide new information, ask follow-up questions to verify it.

IMPORTANT: If they mention anything supernatural, fictional, or impossible (aliens, superpowers, magic, time travel, etc.), immediately call them out and demand a realistic explanation. Don't accept any cop-outs.

Respond to their latest statement: "${actualPlayerResponse}"`;

            userPrompt = `Player's response: "${actualPlayerResponse}"`;
        }

        // Call OpenAI API
        const response = await axios.post(OPENAI_API_URL, {
            model: 'gpt-4o',
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userPrompt }
            ],
            max_tokens: 500,
            temperature: 0.8
        }, {
            headers: {
                'Authorization': `Bearer ${OPENAI_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        const gptResponse = response.data.choices[0].message.content;

        // Log successful response
        console.log('✅ Successfully processed interrogation request:', {
            playerName: cleanPlayerName,
            role: cleanRole,
            difficulty: cleanDifficulty,
            isFirstMessage,
            responseLength: gptResponse.length
        });

        // Return the response
        res.json({
            response: gptResponse,
            scenario: scenario || null,
            evidence: finalEvidenceList,
            difficulty: cleanDifficulty,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('❌ Error in /interrogate endpoint:', error.response?.data || error.message);
        
        res.status(500).json({
            error: 'Failed to get response from AI',
            details: error.response?.data || error.message
        });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        openai_configured: !!OPENAI_API_KEY,
        active_sessions: Object.keys(sessions).length
    });
});

// Debug endpoint to view active sessions (remove in production)
app.get('/debug/sessions', (req, res) => {
    const sessionInfo = Object.keys(sessions).map(playerName => ({
        playerName,
        scenario: sessions[playerName].scenario,
        historyLength: sessions[playerName].history.length,
        timestamp: new Date(sessions[playerName].timestamp).toISOString()
    }));
    
    res.json({
        activeSessions: sessionInfo,
        totalSessions: Object.keys(sessions).length
    });
});

// Start server
app.listen(PORT, config.HOST, () => {
    console.log(`🚀 Alibi Middleware Server running on port ${PORT}`);
    console.log(`🌐 Environment: ${config.IS_PRODUCTION ? 'Production' : 'Development'}`);
    if (config.IS_RAILWAY) {
        console.log(`🚂 Railway deployment detected`);
    }
    console.log(`📡 POST /interrogate - Main interrogation endpoint`);
    console.log(`💚 GET /health - Health check endpoint`);
    console.log(`🔑 OpenAI API: ${OPENAI_API_KEY ? '✅ Configured' : '❌ Missing'}`);
    console.log(`🛡️ Rate limiting: ${config.RATE_LIMIT_MAX_REQUESTS} requests per ${config.RATE_LIMIT_WINDOW / 1000 / 60} minutes`);
});

module.exports = app; 