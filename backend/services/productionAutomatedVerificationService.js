const axios = require('axios');
const logger = require('../utils/logger');

/**
 * Production Automated Verification Service
 * Integrates with real government and commercial APIs for business verification
 */
class ProductionAutomatedVerificationService {
  constructor() {
    // Real API Keys from environment variables
    this.THOMSON_REUTERS_API_KEY = process.env.THOMSON_REUTERS_API_KEY;
    this.LEXISNEXIS_API_KEY = process.env.LEXISNEXIS_API_KEY;
    this.DNB_API_KEY = process.env.DNB_API_KEY;
    this.BBB_API_KEY = process.env.BBB_API_KEY;
    
    // State APIs
    this.COLORADO_SOS_API_KEY = process.env.COLORADO_SOS_API_KEY;
    this.CALIFORNIA_SOS_API_KEY = process.env.CALIFORNIA_SOS_API_KEY;
    this.TEXAS_SOS_API_KEY = process.env.TEXAS_SOS_API_KEY;
    
    // Health Department APIs
    this.DENVER_HEALTH_API_KEY = process.env.DENVER_HEALTH_API_KEY;
    this.BOULDER_HEALTH_API_KEY = process.env.BOULDER_HEALTH_API_KEY;
    
    // API Base URLs
    this.API_ENDPOINTS = {
      thomsonReuters: 'https://api.thomsonreuters.com/clear/business',
      lexisNexis: 'https://api.lexisnexis.com/business-verification/v1',
      dnb: 'https://api.dnb.com/v1/data/duns',
      bbb: 'https://api.bbb.org/v1/business',
      coloradoSOS: 'https://api.sos.state.co.us/biz',
      californiaSOS: 'https://api.sos.ca.gov/business',
      texasSOS: 'https://api.sos.state.tx.us/business',
      denverHealth: 'https://api.denverhealth.org/permits',
      boulderHealth: 'https://api.bouldercounty.org/health/permits'
    };

    console.log('🤖 Production Automated Verification Service initialized');
    this.logAPIStatus();
  }

  /**
   * Log which APIs are available based on environment variables
   */
  logAPIStatus() {
    const apis = {
      'Thomson Reuters': !!this.THOMSON_REUTERS_API_KEY,
      'LexisNexis': !!this.LEXISNEXIS_API_KEY,
      'D&B': !!this.DNB_API_KEY,
      'BBB': !!this.BBB_API_KEY,
      'Colorado SOS': !!this.COLORADO_SOS_API_KEY,
      'California SOS': !!this.CALIFORNIA_SOS_API_KEY,
      'Texas SOS': !!this.TEXAS_SOS_API_KEY
    };

    console.log('📊 API Availability:');
    Object.entries(apis).forEach(([name, available]) => {
      console.log(`  ${available ? '✅' : '❌'} ${name}`);
    });
  }

  /**
   * Main automated verification function
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

    console.log(`🤖 Starting PRODUCTION verification for: ${businessName}`);

    const verificationResults = {
      overall: { verified: false, confidence: 0 },
      checks: {
        ein: { verified: false, confidence: 0, details: null },
        stateRegistration: { verified: false, confidence: 0, details: null },
        foodPermit: { verified: false, confidence: 0, details: null },
        businessLicense: { verified: false, confidence: 0, details: null }
      },
      requiresManualReview: false,
      automatedScore: 0,
      apiCallsUsed: []
    };

    try {
      // 1. EIN Verification - Try multiple services in order of preference
      if (ein) {
        verificationResults.checks.ein = await this.verifyEINProduction(ein, businessName);
      }

      // 2. State Business Registration
      if (businessLicenseNumber && businessState) {
        verificationResults.checks.stateRegistration = await this.verifyStateRegistrationProduction(
          businessLicenseNumber, businessName, businessState
        );
      }

      // 3. Food Service Permit Verification
      if (foodServicePermit) {
        verificationResults.checks.foodPermit = await this.verifyFoodServicePermitProduction(
          foodServicePermit, businessName, businessState
        );
      }

      // 4. Business License Cross-Reference
      verificationResults.checks.businessLicense = await this.verifyBusinessLicenseProduction(
        businessLicenseNumber, businessName, businessState
      );

      // Calculate overall confidence score
      verificationResults.automatedScore = this.calculateConfidenceScore(verificationResults.checks);
      
      // Determine verification outcome
      if (verificationResults.automatedScore >= 80) {
        verificationResults.overall.verified = true;
        verificationResults.overall.confidence = verificationResults.automatedScore;
        console.log(`✅ PRODUCTION verification PASSED for ${businessName} (Score: ${verificationResults.automatedScore})`);
      } else if (verificationResults.automatedScore >= 50) {
        verificationResults.requiresManualReview = true;
        console.log(`⚠️ PRODUCTION verification PARTIAL for ${businessName} (Score: ${verificationResults.automatedScore})`);
      } else {
        verificationResults.requiresManualReview = true;
        console.log(`❌ PRODUCTION verification FAILED for ${businessName} (Score: ${verificationResults.automatedScore})`);
      }

    } catch (error) {
      console.error('❌ Production verification error:', error);
      verificationResults.requiresManualReview = true;
      verificationResults.error = error.message;
    }

    return verificationResults;
  }

  /**
   * Production EIN verification using commercial APIs
   */
  async verifyEINProduction(ein, businessName) {
    // Try Thomson Reuters CLEAR first (most reliable)
    if (this.THOMSON_REUTERS_API_KEY) {
      try {
        const response = await axios.post(`${this.API_ENDPOINTS.thomsonReuters}/ein-verify`, {
          ein: ein.replace(/\D/g, ''), // Remove non-digits
          businessName: businessName
        }, {
          headers: {
            'Authorization': `Bearer ${this.THOMSON_REUTERS_API_KEY}`,
            'Content-Type': 'application/json'
          },
          timeout: 15000
        });

        if (response.data.verified) {
          return {
            verified: true,
            confidence: 95,
            details: {
              source: 'Thomson Reuters CLEAR',
              einStatus: response.data.status,
              businessNameMatch: response.data.nameMatchScore,
              filingStatus: response.data.filingStatus,
              lastUpdated: new Date().toISOString()
            }
          };
        }
      } catch (error) {
        console.warn(`Thomson Reuters EIN verification failed: ${error.message}`);
      }
    }

    // Fallback to LexisNexis
    if (this.LEXISNEXIS_API_KEY) {
      try {
        const response = await axios.get(`${this.API_ENDPOINTS.lexisNexis}/ein/${ein}`, {
          headers: {
            'Authorization': `Bearer ${this.LEXISNEXIS_API_KEY}`,
            'Accept': 'application/json'
          },
          params: {
            businessName: businessName
          },
          timeout: 15000
        });

        if (response.data.isValid) {
          return {
            verified: true,
            confidence: 88,
            details: {
              source: 'LexisNexis',
              einStatus: response.data.status,
              businessNameMatch: response.data.nameMatch,
              confidence: response.data.confidence,
              lastUpdated: new Date().toISOString()
            }
          };
        }
      } catch (error) {
        console.warn(`LexisNexis EIN verification failed: ${error.message}`);
      }
    }

    return {
      verified: false,
      confidence: 0,
      details: { 
        error: 'No EIN verification APIs available',
        fallbackRequired: true,
        availableAPIs: [
          this.THOMSON_REUTERS_API_KEY ? 'Thomson Reuters' : null,
          this.LEXISNEXIS_API_KEY ? 'LexisNexis' : null
        ].filter(Boolean)
      }
    };
  }

  /**
   * Production state business registration verification
   */
  async verifyStateRegistrationProduction(licenseNumber, businessName, state) {
    const stateApiMap = {
      'Colorado': {
        apiKey: this.COLORADO_SOS_API_KEY,
        endpoint: this.API_ENDPOINTS.coloradoSOS
      },
      'California': {
        apiKey: this.CALIFORNIA_SOS_API_KEY,
        endpoint: this.API_ENDPOINTS.californiaSOS
      },
      'Texas': {
        apiKey: this.TEXAS_SOS_API_KEY,
        endpoint: this.API_ENDPOINTS.texasSOS
      }
    };

    const stateConfig = stateApiMap[state];
    if (!stateConfig || !stateConfig.apiKey) {
      return {
        verified: false,
        confidence: 0,
        details: { 
          error: `No API integration available for ${state}`,
          fallbackRequired: true 
        }
      };
    }

    try {
      const response = await axios.get(`${stateConfig.endpoint}/search`, {
        params: {
          licenseNumber: licenseNumber,
          businessName: businessName,
          apiKey: stateConfig.apiKey
        },
        timeout: 12000
      });

      if (response.data.found && response.data.status === 'Active') {
        return {
          verified: true,
          confidence: 92,
          details: {
            source: `${state} Secretary of State`,
            registrationStatus: response.data.status,
            registrationDate: response.data.registrationDate,
            businessType: response.data.businessType,
            filingNumber: response.data.filingNumber,
            lastUpdated: new Date().toISOString()
          }
        };
      } else {
        return {
          verified: false,
          confidence: 25,
          details: { 
            source: `${state} Secretary of State`,
            reason: response.data.found ? 'Business inactive' : 'Business not found',
            searchedLicense: licenseNumber
          }
        };
      }

    } catch (error) {
      console.warn(`${state} SOS verification failed: ${error.message}`);
      return {
        verified: false,
        confidence: 0,
        details: { 
          error: `${state} API unavailable: ${error.message}`,
          fallbackRequired: true 
        }
      };
    }
  }

  /**
   * Production food service permit verification
   */
  async verifyFoodServicePermitProduction(permitNumber, businessName, state) {
    // Try local health department APIs based on state/city
    if (state === 'Colorado') {
      // Try Denver Health Department
      if (this.DENVER_HEALTH_API_KEY) {
        try {
          const response = await axios.get(`${this.API_ENDPOINTS.denverHealth}/verify`, {
            params: {
              permitNumber: permitNumber,
              businessName: businessName,
              permitType: 'mobile_food_vendor'
            },
            headers: {
              'Authorization': `Bearer ${this.DENVER_HEALTH_API_KEY}`
            },
            timeout: 10000
          });

          if (response.data.valid && response.data.status === 'Current') {
            return {
              verified: true,
              confidence: 90,
              details: {
                source: 'Denver Health Department',
                permitStatus: response.data.status,
                expirationDate: response.data.expirationDate,
                permitType: response.data.permitType,
                inspectionGrade: response.data.lastInspectionGrade,
                lastUpdated: new Date().toISOString()
              }
            };
          }
        } catch (error) {
          console.warn(`Denver Health permit verification failed: ${error.message}`);
        }
      }

      // Try Boulder County as fallback
      if (this.BOULDER_HEALTH_API_KEY) {
        try {
          const response = await axios.get(`${this.API_ENDPOINTS.boulderHealth}/verify`, {
            params: {
              permitNumber: permitNumber,
              businessName: businessName
            },
            headers: {
              'Authorization': `Bearer ${this.BOULDER_HEALTH_API_KEY}`
            },
            timeout: 10000
          });

          if (response.data.isValid) {
            return {
              verified: true,
              confidence: 85,
              details: {
                source: 'Boulder County Health',
                permitStatus: response.data.status,
                expirationDate: response.data.expirationDate,
                lastUpdated: new Date().toISOString()
              }
            };
          }
        } catch (error) {
          console.warn(`Boulder Health permit verification failed: ${error.message}`);
        }
      }
    }

    return {
      verified: false,
      confidence: 0,
      details: { 
        error: `No food permit API available for ${state}`,
        fallbackRequired: true,
        recommendation: 'Manual verification with local health department required'
      }
    };
  }

  /**
   * Production business license verification using commercial APIs
   */
  async verifyBusinessLicenseProduction(licenseNumber, businessName, state) {
    const checks = [];

    // Check D&B (Dun & Bradstreet)
    if (this.DNB_API_KEY) {
      checks.push(this.checkDNBDatabase(businessName, state));
    }

    // Check Better Business Bureau
    if (this.BBB_API_KEY) {
      checks.push(this.checkBBBDatabase(businessName, state));
    }

    try {
      const results = await Promise.allSettled(checks);
      const successfulChecks = results.filter(result => 
        result.status === 'fulfilled' && result.value.verified
      );

      if (successfulChecks.length >= 2) {
        return {
          verified: true,
          confidence: 85,
          details: {
            matchingSources: successfulChecks.length,
            sources: successfulChecks.map(check => check.value.source),
            lastUpdated: new Date().toISOString()
          }
        };
      } else if (successfulChecks.length === 1) {
        return {
          verified: true,
          confidence: 65,
          details: {
            matchingSources: 1,
            source: successfulChecks[0].value.source,
            requiresAdditionalVerification: true,
            lastUpdated: new Date().toISOString()
          }
        };
      } else {
        return {
          verified: false,
          confidence: 20,
          details: { 
            reason: 'No matching records found in available databases',
            checkedSources: results.length,
            lastUpdated: new Date().toISOString()
          }
        };
      }

    } catch (error) {
      console.warn(`Business license verification failed: ${error.message}`);
      return {
        verified: false,
        confidence: 0,
        details: { 
          error: 'Business license verification APIs unavailable',
          fallbackRequired: true 
        }
      };
    }
  }

  /**
   * Check D&B (Dun & Bradstreet) database
   */
  async checkDNBDatabase(businessName, state) {
    try {
      const response = await axios.get(`${this.API_ENDPOINTS.dnb}/search`, {
        params: {
          name: businessName,
          state: state,
          countryCode: 'US'
        },
        headers: {
          'Authorization': `Bearer ${this.DNB_API_KEY}`,
          'Accept': 'application/json'
        },
        timeout: 12000
      });

      if (response.data.searchResultsCount > 0) {
        const match = response.data.searchResults[0];
        return {
          verified: true,
          confidence: 80,
          source: 'Dun & Bradstreet',
          details: {
            dunsNumber: match.organization.duns,
            primaryName: match.organization.primaryName,
            isActive: match.organization.corporateLinkage.isActive,
            businessRegistrationNumber: match.organization.registrationNumbers?.[0]?.registrationNumber
          }
        };
      } else {
        return { verified: false, confidence: 0, source: 'D&B' };
      }

    } catch (error) {
      console.warn(`D&B verification failed: ${error.message}`);
      return { verified: false, confidence: 0, source: 'D&B', error: error.message };
    }
  }

  /**
   * Check Better Business Bureau database
   */
  async checkBBBDatabase(businessName, state) {
    try {
      const response = await axios.get(`${this.API_ENDPOINTS.bbb}/search`, {
        params: {
          businessName: businessName,
          state: state
        },
        headers: {
          'Authorization': `Bearer ${this.BBB_API_KEY}`,
          'Accept': 'application/json'
        },
        timeout: 10000
      });

      if (response.data.businesses && response.data.businesses.length > 0) {
        const business = response.data.businesses[0];
        return {
          verified: true,
          confidence: 60, // Lower confidence as BBB is not government
          source: 'Better Business Bureau',
          details: {
            bbbId: business.bbbId,
            rating: business.rating,
            accredited: business.accredited,
            businessAddress: business.address,
            yearsInBusiness: business.yearsInBusiness
          }
        };
      } else {
        return { verified: false, confidence: 0, source: 'BBB' };
      }

    } catch (error) {
      console.warn(`BBB verification failed: ${error.message}`);
      return { verified: false, confidence: 0, source: 'BBB', error: error.message };
    }
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
}

module.exports = ProductionAutomatedVerificationService;
