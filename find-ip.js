// Script to find your computer's IP address
const os = require('os');

function getLocalIPAddress() {
    const interfaces = os.networkInterfaces();
    
    console.log('🌐 Available network interfaces:');
    console.log('================================');
    
    for (const name of Object.keys(interfaces)) {
        for (const interface of interfaces[name]) {
            // Skip internal (i.e. 127.0.0.1) and non-ipv4 addresses
            if (interface.family === 'IPv4' && !interface.internal) {
                console.log(`📡 ${name}: ${interface.address}`);
            }
        }
    }
    
    console.log('\n💡 To use this server with other players:');
    console.log('1. Choose an IP address from above (usually starts with 192.168.x.x or 10.x.x.x)');
    console.log('2. Update the NETWORK_IP in config.js');
    console.log('3. Update the MIDDLEWARE_URL in your Roblox script');
    console.log('4. Make sure your firewall allows connections on port 3000');
    console.log('\n🔧 Example config.js update:');
    console.log('   NETWORK_IP: "192.168.1.100", // Replace with your actual IP');
    console.log('\n🔧 Example Roblox script update:');
    console.log('   local MIDDLEWARE_URL = "http://192.168.1.100:3000"');
}

getLocalIPAddress(); 