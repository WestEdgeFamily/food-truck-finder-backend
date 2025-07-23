#!/usr/bin/env node

/**
 * API Sign-up Helper Script
 * Guides through the process of obtaining real government and commercial API keys
 */

const readline = require('readline');
const fs = require('fs');
const path = require('path');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const APIs = {
  essential: [
    {
      name: 'Thomson Reuters CLEAR',
      purpose: 'EIN Verification',
      cost: '$25/month + $0.25 per lookup',
      signup: 'https://legal.thomsonreuters.com/en/products/clear-investigation-software',
      approval: '1-2 business days',
      priority: 1
    },
    {
      name: 'Colorado Secretary of State',
      purpose: 'Business Registration Verification',
      cost: 'Free',
      signup: 'https://www.sos.state.co.us/biz/BusinessEntitySearchCriteria.do',
      approval: 'Immediate',
      priority: 1
    },
    {
      name: 'Better Business Bureau API',
      purpose: 'Business Credibility Check',
      cost: '$50/month + setup fee',
      signup: 'https://www.bbb.org/api-access-request',
      approval: '3-5 business days',
      priority: 2
    }
  ],
  premium: [
    {
      name: 'LexisNexis Business Verification',
      purpose: 'EIN & Business Identity Verification',
      cost: '$150/month + per lookup',
      signup: 'https://risk.lexisnexis.com/products/business-verification',
      approval: '2-3 business days',
      priority: 2
    },
    {
      name: 'Dun & Bradstreet API',
      purpose: 'Comprehensive Business Data',
      cost: '$99/month + per lookup',
      signup: 'https://www.dnb.com/products/marketing-sales/dnb-api.html',
      approval: '1-2 business days',
      priority: 2
    },
    {
      name: 'California Secretary of State',
      purpose: 'Multi-state Business Registration',
      cost: '$0.10 per lookup',
      signup: 'https://bizfileonline.sos.ca.gov/api',
      approval: '1-2 business days',
      priority: 3
    }
  ]
};

async function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
}

function printHeader() {
  console.log('\n🏛️  GOVERNMENT API INTEGRATION SETUP');
  console.log('=====================================');
  console.log('This script will guide you through obtaining real API keys');
  console.log('for automated business verification.\n');
}

function printAPIInfo(api) {
  console.log(`📋 ${api.name}`);
  console.log(`   Purpose: ${api.purpose}`);
  console.log(`   Cost: ${api.cost}`);
  console.log(`   Signup: ${api.signup}`);
  console.log(`   Approval Time: ${api.approval}`);
  console.log('');
}

async function chooseAPIs() {
  console.log('🎯 STEP 1: Choose your API integration level\n');
  
  console.log('1. 🚀 STARTER ($100-200/month) - Basic verification');
  console.log('2. 💼 PROFESSIONAL ($300-500/month) - Full verification');
  console.log('3. 🏢 ENTERPRISE ($500-1000/month) - All features');
  console.log('4. 🔧 CUSTOM - Let me choose specific APIs\n');

  const choice = await question('Choose your level (1-4): ');
  
  let selectedAPIs = [];
  
  switch(choice.trim()) {
    case '1':
      selectedAPIs = APIs.essential.filter(api => api.priority <= 1);
      break;
    case '2':
      selectedAPIs = [...APIs.essential, ...APIs.premium.filter(api => api.priority <= 2)];
      break;
    case '3':
      selectedAPIs = [...APIs.essential, ...APIs.premium];
      break;
    case '4':
      selectedAPIs = await customAPISelection();
      break;
    default:
      console.log('Invalid choice, defaulting to Starter level.');
      selectedAPIs = APIs.essential.filter(api => api.priority <= 1);
  }

  return selectedAPIs;
}

async function customAPISelection() {
  console.log('\n🔧 CUSTOM API SELECTION\n');
  
  const allAPIs = [...APIs.essential, ...APIs.premium];
  const selected = [];
  
  for (const api of allAPIs) {
    printAPIInfo(api);
    const choice = await question(`Add ${api.name}? (y/N): `);
    if (choice.toLowerCase().startsWith('y')) {
      selected.push(api);
    }
    console.log('');
  }
  
  return selected;
}

function generateSignupPlan(selectedAPIs) {
  console.log('\n📋 YOUR API SIGNUP PLAN');
  console.log('========================\n');
  
  let totalMonthlyCost = 0;
  
  selectedAPIs.forEach((api, index) => {
    console.log(`${index + 1}. ${api.name}`);
    console.log(`   🎯 Purpose: ${api.purpose}`);
    console.log(`   💰 Cost: ${api.cost}`);
    console.log(`   🔗 Signup: ${api.signup}`);
    console.log(`   ⏱️  Approval: ${api.approval}`);
    console.log('');
    
    // Rough cost calculation
    const costMatch = api.cost.match(/\$(\d+)/);
    if (costMatch) {
      totalMonthlyCost += parseInt(costMatch[1]);
    }
  });
  
  console.log(`💰 Estimated Monthly Cost: $${totalMonthlyCost}+\n`);
}

function generateEnvironmentFile(selectedAPIs) {
  const envContent = `# Generated API Configuration
# Fill in your actual API keys below

# Database
MONGODB_URI=your_mongodb_production_uri
PORT=5000
JWT_SECRET=your_jwt_secret_key

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# ===== AUTOMATED VERIFICATION API KEYS =====
${selectedAPIs.map(api => {
  const envVar = api.name.toUpperCase()
    .replace(/[^A-Z0-9]/g, '_')
    .replace(/_{2,}/g, '_');
  return `${envVar}_API_KEY=your_${api.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}_api_key`;
}).join('\n')}

# Verification Settings
AUTO_APPROVAL_THRESHOLD=80
MANUAL_REVIEW_THRESHOLD=50
VERIFICATION_TIMEOUT_MS=15000

# Admin Settings
ADMIN_EMAIL=admin@foodtruckfinder.com
`;

  const envPath = path.join(__dirname, '.env.production');
  fs.writeFileSync(envPath, envContent);
  
  console.log(`📁 Environment file created: ${envPath}`);
  console.log('   Fill in your API keys when you receive them.\n');
}

function printNextSteps(selectedAPIs) {
  console.log('🚀 NEXT STEPS');
  console.log('=============\n');
  
  console.log('1. 📝 Sign up for your selected APIs (in order of priority):');
  selectedAPIs
    .sort((a, b) => a.priority - b.priority)
    .forEach((api, index) => {
      console.log(`   ${index + 1}. ${api.name} - ${api.signup}`);
    });
  
  console.log('\n2. 🔑 Update .env.production with your API keys');
  console.log('3. 🚀 Deploy to Render with new environment variables');
  console.log('4. 🧪 Test verification with real business data');
  console.log('\n💡 TIP: Start with free/cheap APIs to test integration');
  console.log('   then add premium services as you scale.\n');
}

async function main() {
  printHeader();
  
  const proceed = await question('Ready to set up real API integrations? (Y/n): ');
  if (proceed.toLowerCase().startsWith('n')) {
    console.log('Setup cancelled.');
    rl.close();
    return;
  }
  
  const selectedAPIs = await chooseAPIs();
  generateSignupPlan(selectedAPIs);
  
  const confirm = await question('Proceed with this plan? (Y/n): ');
  if (confirm.toLowerCase().startsWith('n')) {
    console.log('Setup cancelled.');
    rl.close();
    return;
  }
  
  generateEnvironmentFile(selectedAPIs);
  printNextSteps(selectedAPIs);
  
  console.log('🎉 Setup complete! Follow the next steps to get your APIs.');
  rl.close();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { APIs, chooseAPIs, generateSignupPlan };
