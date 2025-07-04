// Configuration file for Alibi Middleware Server
module.exports = {
    // Server configuration
    PORT: process.env.PORT || 3000,
    HOST: '0.0.0.0', // Listen on all network interfaces
    
    // Environment detection
    IS_PRODUCTION: process.env.NODE_ENV === 'production',
    IS_RAILWAY: process.env.RAILWAY_ENVIRONMENT === 'production',
    
    // OpenAI configuration
    OPENAI_MODEL: 'gpt-4o',
    OPENAI_MAX_TOKENS: 500,
    OPENAI_TEMPERATURE: 0.8,
    
    // Game configuration
    INTERROGATION_TIME: 900, // 15 minutes in seconds
    RESPONSE_TIME_LIMIT: 60, // 1 minute to respond
    
    // CORS settings - more restrictive for production
    CORS_ORIGIN: process.env.NODE_ENV === 'production' 
        ? ['https://www.roblox.com', 'https://web.roblox.com'] 
        : '*',
    
    // Rate limiting
    RATE_LIMIT_WINDOW: 15 * 60 * 1000, // 15 minutes
    RATE_LIMIT_MAX_REQUESTS: 100, // 100 requests per window
    
    // Logging
    LOG_LEVEL: process.env.NODE_ENV === 'production' ? 'warn' : 'info'
}; 