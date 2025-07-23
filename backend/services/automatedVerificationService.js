const logger = require('../utils/logger');

/**
 * Demo/Simulation version of AutomatedVerificationService for testing
 * This simulates government API responses for demonstration purposes
 * 
 * In production, this would connect to real APIs like:
 * - IRS Business Master File API
 * - State Secretary of State APIs  
 * - Local Health Department APIs
 * - Business License Databases
 */
class AutomatedVerificationService {
  constructor() {
    this.simulationMode = true; // Set to false when real APIs are available
    console.log('🤖 Automated Verification Service initialized (Simulation Mode)');
  }

  /**
   * Main automated verification function (DEMO VERSION)
   */
  async verifyBusiness(businessData) {
    const {
      businessName,
      businessLicenseNumber,
      foodServicePermit,
      businessState,
      ein,
      businessPhone,
      businessEmail
    } = businessData;

    console.log(`🤖 [DEMO] Starting automated verification for: ${businessName}`);

    const verificationResults = {
      overall: { verified: false, confidence: 0 },
      checks: {
        ein: { verified: false, confidence: 0, details: null },
        stateRegistration: { verified: false, confidence: 0, details: null },
        foodPermit: { verified: false, confidence: 0, details: null },
        businessLicense: { verified: false, confidence: 0, details: null }
      },
      requiresManualReview: false,
      automatedScore: 0
    };

    try {
      // 🎭 SIMULATION: Create realistic verification scenarios
      await this.simulateDelay(1000); // Simulate API call time

      // EIN Verification (simulate high success rate for demo)
      if (ein && ein.length >= 9) {
        verificationResults.checks.ein = await this.simulateEINVerification(ein, businessName);
      }

      // State Registration
      if (businessLicenseNumber && businessState) {
        verificationResults.checks.stateRegistration = await this.simulateStateVerification(
          businessLicenseNumber, businessName, businessState
        );
      }

      // Food Service Permit
      if (foodServicePermit) {
        verificationResults.checks.foodPermit = await this.simulateFoodPermitVerification(
          foodServicePermit, businessName, businessState
        );
      }

      // Business License Cross-Reference
      verificationResults.checks.businessLicense = await this.simulateBusinessLicenseVerification(
        businessLicenseNumber, businessName, businessState
      );

      // Calculate overall confidence score
      verificationResults.automatedScore = this.calculateConfidenceScore(verificationResults.checks);
      
      // 🎯 Determine verification outcome
      if (verificationResults.automatedScore >= 80) {
        verificationResults.overall.verified = true;
        verificationResults.overall.confidence = verificationResults.automatedScore;
        console.log(`✅ [DEMO] Automated verification PASSED for ${businessName} (Score: ${verificationResults.automatedScore})`);
      } else if (verificationResults.automatedScore >= 50) {
        verificationResults.requiresManualReview = true;
        console.log(`⚠️ [DEMO] Automated verification PARTIAL for ${businessName} (Score: ${verificationResults.automatedScore}) - Manual review required`);
      } else {
        verificationResults.requiresManualReview = true;
        console.log(`❌ [DEMO] Automated verification FAILED for ${businessName} (Score: ${verificationResults.automatedScore}) - Manual review required`);
      }

    } catch (error) {
      console.error('❌ [DEMO] Automated verification error:', error);
      verificationResults.requiresManualReview = true;
      verificationResults.error = error.message;
    }

    return verificationResults;
  }

  /**
   * Simulate EIN verification with realistic scenarios
   */
  async simulateEINVerification(ein, businessName) {
    await this.simulateDelay(500);

    // 🎭 Simulation logic: Create different scenarios based on EIN pattern
    const einScore = this.calculateEINScore(ein, businessName);

    if (einScore >= 90) {
      return {
        verified: true,
        confidence: einScore,
        details: {
          einStatus: 'Active',
          businessNameMatch: 'Exact Match',
          filingStatus: 'Current',
          simulationNote: '[DEMO] IRS EIN verification simulated'
        }
      };
    } else if (einScore >= 60) {
      return {
        verified: true,
        confidence: einScore,
        details: {
          einStatus: 'Active',
          businessNameMatch: 'Partial Match',
          filingStatus: 'Current',
          simulationNote: '[DEMO] IRS EIN verification simulated'
        }
      };
    } else {
      return {
        verified: false,
        confidence: einScore,
        details: {
          reason: 'EIN not found or inactive',
          simulationNote: '[DEMO] IRS EIN verification simulated'
        }
      };
    }
  }

  /**
   * Simulate state business registration verification
   */
  async simulateStateVerification(licenseNumber, businessName, state) {
    await this.simulateDelay(700);

    // 🎭 Simulation: Higher success rates for certain states/patterns
    const stateScore = this.calculateStateScore(licenseNumber, businessName, state);

    if (stateScore >= 85) {
      return {
        verified: true,
        confidence: stateScore,
        details: {
          registrationStatus: 'Active',
          registrationDate: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          businessType: 'Limited Liability Company',
          simulationNote: `[DEMO] ${state} Secretary of State verification simulated`
        }
      };
    } else {
      return {
        verified: false,
        confidence: stateScore,
        details: {
          reason: 'Business registration not found or inactive',
          simulationNote: `[DEMO] ${state} Secretary of State verification simulated`
        }
      };
    }
  }

  /**
   * Simulate food service permit verification
   */
  async simulateFoodPermitVerification(permitNumber, businessName, state) {
    await this.simulateDelay(600);

    const permitScore = this.calculatePermitScore(permitNumber, businessName);

    if (permitScore >= 80) {
      return {
        verified: true,
        confidence: permitScore,
        details: {
          permitStatus: 'Current',
          expirationDate: new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          permitType: 'Mobile Food Vendor',
          simulationNote: `[DEMO] ${state} Health Department verification simulated`
        }
      };
    } else {
      return {
        verified: false,
        confidence: permitScore,
        details: {
          reason: 'Food service permit not found or expired',
          simulationNote: `[DEMO] Health Department verification simulated`
        }
      };
    }
  }

  /**
   * Simulate business license cross-reference
   */
  async simulateBusinessLicenseVerification(licenseNumber, businessName, state) {
    await this.simulateDelay(400);

    const licenseScore = this.calculateLicenseScore(licenseNumber, businessName);

    if (licenseScore >= 75) {
      return {
        verified: true,
        confidence: licenseScore,
        details: {
          matchingSources: 2,
          sources: ['Business Registry Database', 'Professional License Database'],
          simulationNote: '[DEMO] Cross-reference verification simulated'
        }
      };
    } else {
      return {
        verified: false,
        confidence: licenseScore,
        details: {
          reason: 'Limited matching records found',
          simulationNote: '[DEMO] Cross-reference verification simulated'
        }
      };
    }
  }

  /**
   * Simulation scoring algorithms (for demo purposes)
   */
  calculateEINScore(ein, businessName) {
    // Simple algorithm for demo: longer EIN + business name = higher score
    let score = 30;
    if (ein && ein.length >= 9) score += 40;
    if (businessName && businessName.length > 5) score += 30;
    
    // Add some randomness to simulate real-world variability
    score += Math.random() * 20 - 10;
    
    return Math.max(0, Math.min(100, Math.round(score)));
  }

  calculateStateScore(licenseNumber, businessName, state) {
    let score = 40;
    if (licenseNumber && licenseNumber.length >= 6) score += 30;
    if (businessName && businessName.includes('Food')) score += 20;
    if (['Colorado', 'California', 'Texas'].includes(state)) score += 10; // Demo states with "good" APIs
    
    score += Math.random() * 20 - 10;
    return Math.max(0, Math.min(100, Math.round(score)));
  }

  calculatePermitScore(permitNumber, businessName) {
    let score = 35;
    if (permitNumber && permitNumber.length >= 5) score += 35;
    if (businessName && (businessName.toLowerCase().includes('truck') || businessName.toLowerCase().includes('food'))) score += 20;
    
    score += Math.random() * 20 - 10;
    return Math.max(0, Math.min(100, Math.round(score)));
  }

  calculateLicenseScore(licenseNumber, businessName) {
    let score = 30;
    if (licenseNumber && licenseNumber.length >= 4) score += 25;
    if (businessName && businessName.length > 10) score += 25;
    
    score += Math.random() * 30 - 15;
    return Math.max(0, Math.min(100, Math.round(score)));
  }

  /**
   * Calculate overall confidence score from individual checks
   */
  calculateConfidenceScore(checks) {
    const weights = {
      ein: 0.3,
      stateRegistration: 0.3,
      foodPermit: 0.25,
      businessLicense: 0.15
    };

    let totalScore = 0;
    let totalWeight = 0;

    Object.keys(checks).forEach(checkType => {
      if (checks[checkType].confidence > 0) {
        totalScore += checks[checkType].confidence * weights[checkType];
        totalWeight += weights[checkType];
      }
    });

    return totalWeight > 0 ? Math.round(totalScore / totalWeight) : 0;
  }

  /**
   * Simulate API call delay
   */
  async simulateDelay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = AutomatedVerificationService;
