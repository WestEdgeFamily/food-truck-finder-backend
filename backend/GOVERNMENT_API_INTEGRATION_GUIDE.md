# Government API Integration Guide

## 🏛️ IRS Business Verification

### Option 1: IRS Business Master File (BMF) API
- **Access Level**: Requires special authorization from IRS
- **Cost**: Varies, typically $0.10-$0.50 per lookup
- **How to Apply**: 
  1. Visit: https://www.irs.gov/statistics/soi-tax-stats-business-master-file-bmf-extract
  2. Submit Form 4506-A (Request for Public Inspection)
  3. Business justification required
- **Response Time**: 2-4 weeks for approval
- **Data Returned**: EIN status, business name, filing status

### Option 2: Thomson Reuters CLEAR API (Recommended)
- **Access**: Commercial service with IRS data
- **Cost**: $15-25/month + $0.25 per lookup
- **Sign Up**: https://legal.thomsonreuters.com/en/products/clear-investigation-software
- **Faster**: 1-2 business days approval
- **Data**: EIN verification, business registration, tax status

### Option 3: LexisNexis Business Verification
- **Access**: Commercial API with government data access
- **Cost**: $50/month + per-lookup fees
- **Sign Up**: https://risk.lexisnexis.com/products/business-verification
- **Features**: Real-time EIN verification, business identity

## 🏢 State Business Registration APIs

### Colorado Secretary of State
- **API**: Colorado Information Marketplace (CIM)
- **Cost**: Free for basic lookups
- **Sign Up**: https://www.sos.state.co.us/biz/BusinessEntitySearchCriteria.do
- **Endpoint**: `https://api.sos.state.co.us/biz/search`

### California Secretary of State
- **API**: Business Search API
- **Cost**: $0.10 per lookup
- **Sign Up**: https://bizfileonline.sos.ca.gov/api
- **Endpoint**: `https://api.sos.ca.gov/business/search`

### Texas Secretary of State
- **API**: SOSDirect Business Search
- **Cost**: $1.00 per lookup
- **Sign Up**: https://www.sos.state.tx.us/corp/sosda/
- **Endpoint**: `https://api.sos.state.tx.us/business/search`

## 🏥 Health Department APIs

### Denver Health Department
- **Contact**: Denver Environmental Health
- **Phone**: (303) 602-6000
- **Request**: Food establishment permit verification API
- **Cost**: Usually free for legitimate business use

### Boulder County Health
- **Contact**: Boulder County Public Health
- **Phone**: (303) 441-1100
- **API**: Custom integration required

## 📋 Business License Verification

### Option 1: SBA Business Registry
- **API**: Small Business Administration Registry
- **Cost**: Free
- **Sign Up**: https://www.sba.gov/partners/lenders/participant-lenders/small-business-lending-company-sblc-program
- **Limited**: Only SBA-registered businesses

### Option 2: Dun & Bradstreet API
- **Service**: D&B Direct+ API
- **Cost**: $99/month + per-lookup
- **Sign Up**: https://www.dnb.com/products/marketing-sales/dnb-api.html
- **Features**: Business verification, credit reports, registration status

### Option 3: Better Business Bureau API
- **Service**: BBB Business Profiles API
- **Cost**: $500 setup + monthly fees
- **Contact**: https://www.bbb.org/api-access-request
- **Features**: Business ratings, complaints, verification status

## 🔧 Implementation Priority

### Phase 1: Basic (Free/Low Cost)
1. **Colorado SOS API** - Free business lookup
2. **BBB API** - Business credibility 
3. **Manual EIN verification** - Fallback system

### Phase 2: Premium (Paid APIs)
1. **Thomson Reuters CLEAR** - EIN verification
2. **California & Texas SOS** - Multi-state support
3. **D&B API** - Comprehensive business data

### Phase 3: Full Integration
1. **Local Health Department APIs** - Food permit verification
2. **Multi-state expansion** - All 50 states
3. **Real-time monitoring** - Status change notifications

## 💰 Cost Estimate (Monthly)

### Starter Package ($100-200/month):
- Thomson Reuters CLEAR: $25/month + usage
- Colorado SOS: Free
- BBB API: $50/month
- D&B Basic: $99/month

### Professional Package ($300-500/month):
- All starter features
- California & Texas SOS: $50/month
- LexisNexis: $150/month
- Health department integrations: $100/month

### Enterprise Package ($500-1000/month):
- All professional features
- Multi-state coverage: $200/month
- Real-time monitoring: $100/month
- Priority support: $200/month
