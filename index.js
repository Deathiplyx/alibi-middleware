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
    let cleanedCount = 0;
    
    Object.keys(sessions).forEach(playerName => {
        if (now - sessions[playerName].timestamp > sessionTimeout) {
            delete sessions[playerName];
            cleanedCount++;
            console.log(`🧹 Cleaned up expired session for ${playerName}`);
        }
    });
    
    if (cleanedCount > 0) {
        console.log(`🧹 Cleaned up ${cleanedCount} expired sessions`);
    }
}

// Session validation function
function validateSession(session) {
    if (!session || !session.scenario || !session.evidence) {
        return false;
    }
    
    // Check if session has required fields
    const requiredFields = ['crime', 'location', 'time', 'method'];
    for (const field of requiredFields) {
        if (!session.scenario[field]) {
            return false;
        }
    }
    
    return true;
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
    "Deployed smoke bombs to disable cameras", "Used sledgehammers to break windows", "Used bolt cutters on locks",
    "Used thermal lances to cut through steel", "Deployed EMP devices to disable electronics",
    "Used hydraulic jacks to force entry", "Employed laser cutting equipment", "Used plasma torches",
    "Deployed distraction devices", "Used ultrasonic cutting tools", "Employed robotic assistance",
    "Used chemical compounds to weaken structures", "Deployed drones for reconnaissance",
    "Used sound dampening equipment", "Employed thermal imaging to find weak points",
    "Used magnetic locks to bypass security", "Deployed smoke screens for cover"
];

const roles = ['Driver', 'Lookout', 'Hacker', 'Muscle', 'Inside Man', 'Mastermind', 'Tech Specialist', 'Demolitions Expert', 'Scout', 'Communications Specialist', 'Safecracker', 'Surveillance Expert', 'Escape Artist', 'Infiltration Specialist', 'Tactical Coordinator', 'Logistics Manager'];
const difficulties = ['Easy', 'Medium', 'Hard', 'Expert'];

// Generate random time with more variety
function generateRandomTime() {
    // Sometimes use late night (10 PM - 4 AM), sometimes use other times
    const timeRanges = [
        { start: 22, end: 28, label: 'late night' }, // 10 PM - 4 AM
        { start: 20, end: 24, label: 'evening' },    // 8 PM - 12 AM
        { start: 0, end: 6, label: 'early morning' }, // 12 AM - 6 AM
        { start: 14, end: 18, label: 'afternoon' },   // 2 PM - 6 PM
        { start: 8, end: 12, label: 'morning' }       // 8 AM - 12 PM
    ];
    
    const selectedRange = timeRanges[Math.floor(Math.random() * timeRanges.length)];
    const hour = Math.floor(Math.random() * (selectedRange.end - selectedRange.start)) + selectedRange.start;
    const minute = Math.floor(Math.random() * 60);
    
    const ampm = hour >= 24 ? 'AM' : (hour >= 12 ? 'PM' : 'AM');
    const displayHour = hour >= 24 ? hour - 24 : (hour > 12 ? hour - 12 : hour);
    const finalHour = displayHour === 0 ? 12 : displayHour;
    
    return `${finalHour}:${minute.toString().padStart(2, '0')} ${ampm}`;
}

// Generate evidence based on difficulty
function generateEvidence(scenario, playerName, difficulty) {
    // Easy: Only weak, circumstantial, or indirect evidence
    const easyEvidence = [
        `A car similar to one registered to ${playerName} was seen in the general area that day`,
        `Someone thought they saw a person matching your description a few blocks away from ${scenario.location}`,
        `You were reportedly in the city on the day of the incident`,
        `A neighbor mentioned seeing you earlier that week, but couldn't recall the exact day`,
        `A receipt shows you made a purchase at a store in the same city earlier that day`,
        `A social media post places you somewhere in town, but not at the scene`,
        `A friend said you mentioned being near ${scenario.location} recently, but wasn't sure when`,
        `A car matching yours was seen driving past a nearby intersection`,
        `A vague tip suggested you might have been in the area, but nothing confirmed`,
        `A distant security camera caught a blurry figure that could possibly be you, but it's unclear`
    ];

    // Normal: Moderate evidence, but not direct or overwhelming
    const normalEvidence = [
        `An eyewitness reported seeing someone matching your description near ${scenario.location} around the time of the incident`,
        `A receipt shows you made a purchase at a store close to ${scenario.location} shortly before the incident`,
        `A single security camera caught a person resembling you walking near ${scenario.location}`,
        `A neighbor saw your car parked a few blocks from ${scenario.location}`,
        `A friend said you mentioned being in the area that day`,
        `A bus ticket places you in the neighborhood earlier that day`,
        `A store clerk remembers seeing you, but isn't certain of the time`,
        `A partial license plate match was reported near the scene`,
        `A witness saw someone with your build and hair color near the scene`,
        `A phone ping places you somewhere in the neighborhood, but not at the scene`
    ];

    // Hard: Strong evidence, but not completely irrefutable
    const hardEvidence = [
        `Two witnesses independently reported seeing you near ${scenario.location} at the time of the incident`,
        `A security camera caught you walking within a block of ${scenario.location} at the time of the incident`,
        `Your phone pinged a tower very close to ${scenario.location} at the time of the incident`,
        `A partial fingerprint match was found on an object near the scene`,
        `A neighbor saw you leaving the area shortly after the incident`,
        `A store receipt shows you made a purchase at a shop next to ${scenario.location} minutes before the incident`,
        `A rideshare record shows you were dropped off near ${scenario.location}`,
        `A witness saw you talking to someone near the scene`,
        `A camera caught your car driving past ${scenario.location} at the time of the incident`,
        `A partial DNA match was found on an item left near the scene`
    ];

    // Expert: Nearly irrefutable evidence
    const expertEvidence = [
        `A security camera clearly shows you at ${scenario.location} at the exact time of the incident`,
        `Your fingerprints were found on the door at ${scenario.location}`,
        `Your DNA was found at the scene`,
        `Multiple witnesses identified you as being at ${scenario.location} at the time of the incident`,
        `Your phone GPS data places you at ${scenario.location} at the exact time`,
        `A digital record shows you accessed a device at ${scenario.location}`,
        `A bank transaction places you at the scene at the exact time`,
        `A police officer saw you at ${scenario.location} during the incident`,
        `A direct message from your account references the incident at ${scenario.location}`,
        `A video shows you entering or leaving ${scenario.location} at the time of the incident`
    ];

    let evidencePool = [];
    if (difficulty === 'Easy') evidencePool = easyEvidence;
    else if (difficulty === 'Medium' || difficulty === 'Normal') evidencePool = normalEvidence;
    else if (difficulty === 'Hard') evidencePool = hardEvidence;
    else if (difficulty === 'Expert') evidencePool = expertEvidence;
    else evidencePool = normalEvidence;

    // Select 3-4 pieces of evidence for Easy/Normal, 4-5 for Hard, 5+ for Expert
    let count = 3;
    if (difficulty === 'Hard') count = 4 + Math.floor(Math.random() * 2);
    if (difficulty === 'Expert') count = 5 + Math.floor(Math.random() * 2);
    if (difficulty === 'Easy' || difficulty === 'Medium' || difficulty === 'Normal') count = 3 + Math.floor(Math.random() * 2);

    // Shuffle and select
    const shuffled = evidencePool.sort(() => Math.random() - 0.5);
    return shuffled.slice(0, count);
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
        let session = sessions[cleanPlayerName];
        
        if (isFirstMessage || !session) {
            // Start new session
            scenario = generateScenario();
            generatedEvidence = generateEvidence(scenario, cleanPlayerName, cleanDifficulty);
            // Store session data (evidence will be regenerated on each question)
            sessions[cleanPlayerName] = {
                scenario: scenario,
                history: [],
                conversationHistory: actualConversationHistory || [],
                timestamp: Date.now()
            };
            session = sessions[cleanPlayerName];
            console.log(`🆕 Started new session for ${cleanPlayerName}:`, {
                crime: scenario.crime,
                location: scenario.location,
                time: scenario.time
            });
        } else {
            // Always use the original scenario from the session
            scenario = session.scenario;
            // Regenerate evidence on each question for more variety
            generatedEvidence = generateEvidence(scenario, cleanPlayerName, cleanDifficulty);
            // Accumulate conversation history
            if (Array.isArray(actualConversationHistory) && actualConversationHistory.length > 0) {
                session.conversationHistory = actualConversationHistory;
            }
            // Update session history (for debugging, not used in prompt)
            session.history.push({
                question: actualConversationHistory[actualConversationHistory.length - 1]?.content || 'Previous question',
                answer: actualPlayerResponse
            });
            session.timestamp = Date.now();
            console.log(`🔄 Continuing session for ${cleanPlayerName}:`, {
                crime: scenario.crime,
                location: scenario.location,
                historyLength: session.history.length,
                conversationLength: session.conversationHistory.length,
                evidenceCount: generatedEvidence.length
            });
        }

        // Use provided evidence list or generated evidence
        const finalEvidenceList = evidenceList || generatedEvidence;

        // Build the situation memory block (never changes)
        const situationMemoryBlock = `====================\nSITUATION MEMORY (DO NOT CHANGE)\n====================\nCRIME: ${scenario.crime}\nLOCATION: ${scenario.location}\nTIME: ${scenario.time}\nMETHOD: ${scenario.method}\n====================\n`;

        // Build the conversation memory block (grows with Q&A)
        const conversationMemoryBlock = (session.conversationHistory || []).map(msg => {
            if (msg.role === 'detective') return `Detective: ${msg.content}`;
            if (msg.role === 'player') return `Player: ${msg.content}`;
            return `${msg.role || 'Unknown'}: ${msg.content}`;
        }).join('\n');

        // Build the prompt based on whether it's the first message or continuation
        let systemPrompt, userPrompt;

        // Difficulty level instructions
        const difficultyInstructions = {
            Easy: `Easy: Be very forgiving, patient, and helpful. Give the player plenty of chances to explain, offer hints, and avoid being aggressive. Only catch them if the evidence is overwhelming and contradictions are blatant. DO NOT catch them for minor timing ambiguities or fuzzy memories. If in doubt, give the player the benefit of the doubt.`,
            Medium: `Normal: Interrogate like a real detective. Be persistent, realistic, and fair. Look for gaps and inconsistencies, but give the player a reasonable chance to explain.`,
            Hard: `Hard: Be tough and relentless. Most people will find this challenging. Press hard on contradictions, use evidence aggressively, and don't let the player off easy.`,
            Expert: `Expert: Be extremely challenging, as if interrogating a seasoned criminal. Use every trick, trap, and piece of evidence. Catch even subtle contradictions and push the player to their limits.`
        };
        const difficultyBlock = `DIFFICULTY LEVEL: ${cleanDifficulty}\n${difficultyInstructions[cleanDifficulty] || ''}`;

        // AI catch explanation instruction
        const catchInstruction = `If you catch the player in a lie or contradiction, you MUST start your response with the exact phrase: 'I caught you in a lie because...' (verbatim, at the very beginning of your explanation, in the same sentence). Immediately explain the reason, referencing the specific evidence, statements, and contradictions that led you to your conclusion. Make your reasoning clear and explicit so the player understands exactly what gave them away. IMPORTANT: Only catch lies based on the evidence list or direct contradictions in their own statements. The crime time is when the crime occurred, NOT when the player was there. Do not treat the crime time as evidence that the player was at the scene.`;

        if (isFirstMessage) {
            systemPrompt = `${situationMemoryBlock}\nYou are Detective Holloway, a seasoned investigator known for your sharp instincts and ability to spot lies. You are interrogating ${cleanPlayerName}, who is suspected of being the ${cleanRole} in the above scenario.\n\n${difficultyBlock}\n\nYour interrogation style:\n- Be professional but firm, matching the difficulty level\n- Ask specific questions about timing, location, and actions\n- Look for contradictions in their story\n- Use the evidence against them strategically\n- Don't let them off easy - push for details\n- If they're lying, call them out on inconsistencies\n- Keep track of what they've said and compare it to evidence\n- Build a case by gathering more information with each question\n- REJECT any supernatural, fictional, or impossible explanations (aliens, superpowers, time travel, etc.)\n- Focus only on real-world possibilities and evidence\n- If they mention impossible things, call them out and demand realistic answers\n\n${catchInstruction}\n\nEVIDENCE GENERATION: You have access to the following evidence, but you can also create additional evidence as the interrogation progresses. Feel free to:\n- Reference new surveillance footage, witness statements, or forensic findings\n- Mention new details about the crime scene, timing, or methods used\n- Introduce new witnesses, security cameras, or physical evidence\n- Create realistic forensic evidence (fingerprints, DNA, tool marks, etc.)\n- Reference financial records, phone records, or digital evidence\n- Mention new locations, vehicles, or accomplices involved\n- Create new details about the crime method, timing, or location\n- Introduce new crime scene details, evidence types, or investigation findings\n\nCurrent evidence against ${cleanPlayerName}:\n${finalEvidenceList.map(evidence => `- ${evidence}`).join('\\n')}\n\nIMPORTANT: As the interrogation progresses, you can introduce new evidence that makes sense for the scenario. Be creative but realistic. The evidence should build the case against the suspect. You can create new details about the crime, witnesses, evidence, or investigation as needed.\n\nStart your interrogation. Ask your first question. Be direct and professional, matching the ${cleanDifficulty} difficulty level.`;
            userPrompt = `${situationMemoryBlock}\nBegin the interrogation with your first question.`;
        } else {
            // Continue the conversation with lie detection and evidence comparison
            systemPrompt = `${situationMemoryBlock}\nCONVERSATION MEMORY (Q&A so far):\n${conversationMemoryBlock}\n\nYou are Detective Holloway continuing your interrogation of ${cleanPlayerName}, the suspected ${cleanRole} in the above scenario.\n\n${difficultyBlock}\n\nYour interrogation style:\n- Be professional but firm, matching the difficulty level\n- Ask specific questions about timing, location, and actions\n- Look for contradictions in their story\n- Use the evidence against them strategically\n- Don't let them off easy - push for details\n- If they're lying, call them out on inconsistencies\n- Keep track of what they've said and compare it to evidence\n- Build a case by gathering more information with each question\n- REJECT any supernatural, fictional, or impossible explanations (aliens, superpowers, time travel, etc.)\n- Focus only on real-world possibilities and evidence\n- If they mention impossible things, call them out and demand realistic answers\n\n${catchInstruction}\n\nEVIDENCE GENERATION: You can introduce new evidence as the interrogation progresses. Feel free to:\n- Reference new surveillance footage, witness statements, or forensic findings\n- Mention new details about the crime scene, timing, or methods used\n- Introduce new witnesses, security cameras, or physical evidence\n- Create realistic forensic evidence (fingerprints, DNA, tool marks, etc.)\n- Reference financial records, phone records, or digital evidence\n- Mention new locations, vehicles, or accomplices involved\n- Create new details about the crime method, timing, or location\n- Introduce new crime scene details, evidence types, or investigation findings\n\nCurrent evidence against ${cleanPlayerName}:\n${finalEvidenceList.map(evidence => `- ${evidence}`).join('\\n')}\n\nANALYZE their latest response: "${actualPlayerResponse}"\n\nCompare what they just said to:\n1. The evidence we have (ONLY use the evidence list above)\n2. What they've said before (look for direct contradictions in their own statements)\n3. The crime details (crime time is when the crime occurred, NOT when the player was there)\n\nIf you find contradictions, lies, or inconsistencies, confront them directly. If they're being evasive, push harder. If they provide new information, ask follow-up questions to verify it.\n\nIMPORTANT: \n- If they mention anything supernatural, fictional, or impossible (aliens, superpowers, magic, time travel, etc.), immediately call them out and demand a realistic explanation. Don't accept any cop-outs.\n- You can introduce new evidence that makes sense for the scenario. Be creative but realistic.\n- The evidence should build the case against the suspect as the interrogation progresses.\n- DO NOT DEVIATE FROM THIS SCENARIO. If the player mentions a different crime, location, time, or method, IGNORE IT and redirect the conversation back to the original scenario. Never reference any crime, location, time, or method except the original scenario. All evidence, questions, and details must relate ONLY to this original scenario for the entire interrogation.\n- CRITICAL: The crime time (${scenario.time}) is when the crime occurred, NOT when the player was there. Do not use the crime time as evidence that the player was at the scene. Only use the evidence list above to catch lies.\n\nRespond to their latest statement: "${actualPlayerResponse}"`;
            userPrompt = `${situationMemoryBlock}\nPlayer's response: "${actualPlayerResponse}"`;
        }

        // Call OpenAI API
        const response = await axios.post(OPENAI_API_URL, {
            model: 'gpt-4o',
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userPrompt }
            ],
            max_tokens: 500,
            temperature: 0.9
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
        
        // Provide more specific error messages
        let errorMessage = 'Failed to get response from AI';
        let errorDetails = error.response?.data || error.message;
        
        if (error.code === 'ECONNRESET' || error.code === 'ETIMEDOUT') {
            errorMessage = 'Connection timeout. Please try again.';
        } else if (error.response?.status === 429) {
            errorMessage = 'Rate limit exceeded. Please wait a moment.';
        } else if (error.response?.status === 401) {
            errorMessage = 'Authentication failed. Please check API key.';
        } else if (error.response?.status === 400) {
            errorMessage = 'Invalid request format.';
        }
        
        res.status(500).json({
            error: errorMessage,
            details: errorDetails,
            timestamp: new Date().toISOString()
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
        conversationLength: sessions[playerName].conversationHistory?.length || 0,
        timestamp: new Date(sessions[playerName].timestamp).toISOString(),
        isValid: validateSession(sessions[playerName])
    }));
    
    res.json({
        activeSessions: sessionInfo,
        totalSessions: Object.keys(sessions).length,
        serverTime: new Date().toISOString()
    });
});

// Debug endpoint to reset sessions (remove in production)
app.post('/debug/reset-sessions', (req, res) => {
    const { playerName } = req.body;
    
    if (playerName) {
        if (sessions[playerName]) {
            delete sessions[playerName];
            res.json({ message: `Session for ${playerName} has been reset` });
        } else {
            res.status(404).json({ error: `No session found for ${playerName}` });
        }
    } else {
        // Reset all sessions
        const count = Object.keys(sessions).length;
        Object.keys(sessions).forEach(key => delete sessions[key]);
        res.json({ message: `All ${count} sessions have been reset` });
    }
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