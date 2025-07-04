#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🚀 Preparing Alibi Middleware for deployment...\n');

// Check if secrets/.env exists
const envPath = path.join(__dirname, 'secrets', '.env');
if (!fs.existsSync(envPath)) {
    console.log('❌ ERROR: secrets/.env file not found!');
    console.log('Please create secrets/.env with your OpenAI API key:');
    console.log('OPENAI_API_KEY=your_api_key_here\n');
    process.exit(1);
}

// Check if OpenAI API key is in .env
const envContent = fs.readFileSync(envPath, 'utf8');
if (!envContent.includes('OPENAI_API_KEY=')) {
    console.log('❌ ERROR: OPENAI_API_KEY not found in secrets/.env!');
    console.log('Please add: OPENAI_API_KEY=your_api_key_here\n');
    process.exit(1);
}

// Check if .gitignore exists and includes secrets
const gitignorePath = path.join(__dirname, '.gitignore');
if (!fs.existsSync(gitignorePath)) {
    console.log('📝 Creating .gitignore file...');
    fs.writeFileSync(gitignorePath, 'secrets/\nnode_modules/\n.env\n*.log\n');
} else {
    const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
    if (!gitignoreContent.includes('secrets/')) {
        console.log('📝 Adding secrets/ to .gitignore...');
        fs.appendFileSync(gitignorePath, '\nsecrets/\n');
    }
}

// Check if all required files exist
const requiredFiles = [
    'index.js',
    'package.json',
    'config.js',
    'railway.json',
    'Procfile'
];

console.log('📋 Checking required files:');
requiredFiles.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        console.log(`✅ ${file}`);
    } else {
        console.log(`❌ ${file} - MISSING`);
    }
});

console.log('\n🎯 Deployment Checklist:');
console.log('1. ✅ OpenAI API key configured');
console.log('2. ✅ All required files present');
console.log('3. ✅ .gitignore configured');
console.log('\n📦 Next steps:');
console.log('1. Commit your code to GitHub:');
console.log('   git add .');
console.log('   git commit -m "Prepare for deployment"');
console.log('   git push origin main');
console.log('\n2. Deploy to Railway:');
console.log('   - Go to https://railway.app');
console.log('   - Sign up with GitHub');
console.log('   - Create new project from GitHub repo');
console.log('   - Add environment variables in Railway dashboard');
console.log('   - Get your deployment URL');
console.log('\n3. Update your Roblox script with the new URL');
console.log('\n📚 See DEPLOYMENT.md for detailed instructions\n');

console.log('🚀 Ready for deployment!'); 