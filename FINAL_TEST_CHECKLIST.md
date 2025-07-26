# Food Truck App - Final Test Checklist ✅

## Pre-Launch Testing Guide

### 🔐 Security & Configuration

- [ ] **API Key Security**
  - [ ] Remove exposed API key from GitHub
  - [ ] Regenerate Google Maps API key in console
  - [ ] Create `android/local.properties` with: `MAPS_API_KEY=your-new-key`
  - [ ] Verify key is NOT in any committed files
  - [ ] Test build with environment variables

- [ ] **Firebase Setup**
  - [ ] Add `google-services.json` to `android/app/`
  - [ ] Add `GoogleService-Info.plist` to `ios/Runner/`
  - [ ] Enable Crashlytics in Firebase Console
  - [ ] Enable Analytics in Firebase Console

### 👤 Customer Flow Testing

- [ ] **Registration & Login**
  - [ ] Register new customer account
  - [ ] Verify email validation works
  - [ ] Test login with correct credentials
  - [ ] Test login with wrong password
  - [ ] Test "Forgot Password" flow
  - [ ] Verify logout clears all data

- [ ] **Food Truck Discovery**
  - [ ] View food truck list
  - [ ] Search for trucks by name
  - [ ] Filter by cuisine type
  - [ ] View truck on map
  - [ ] Test pull-to-refresh
  - [ ] Verify offline mode shows cached data

- [ ] **Truck Details & Interaction**
  - [ ] View truck details page
  - [ ] See menu items with prices
  - [ ] Check operating hours
  - [ ] View location on map
  - [ ] Call truck (if number available)
  - [ ] Visit website (if available)

- [ ] **Favorites System**
  - [ ] Add truck to favorites
  - [ ] Remove from favorites
  - [ ] View favorites list
  - [ ] Receive notification when favorite truck nearby

- [ ] **Reviews**
  - [ ] Write a review with rating
  - [ ] View existing reviews
  - [ ] Test review validation (min/max length)

### 🚚 Owner Flow Testing

- [ ] **Registration & Verification**
  - [ ] Register new owner account
  - [ ] Complete business verification
  - [ ] Test auto-verification (if enabled)
  - [ ] Login as owner

- [ ] **Truck Management**
  - [ ] Create/edit truck profile
  - [ ] Upload cover photo
  - [ ] Update business hours
  - [ ] Set location manually
  - [ ] Test location tracking

- [ ] **Menu Management**
  - [ ] Add menu items
  - [ ] Edit prices
  - [ ] Delete items
  - [ ] Mark items as unavailable

- [ ] **Schedule Management**
  - [ ] Set weekly schedule
  - [ ] Create special events
  - [ ] Update operating status (open/closed)

- [ ] **POS Integration**
  - [ ] Select POS system
  - [ ] Connect account (OAuth flow)
  - [ ] Test connection
  - [ ] Verify data sync

- [ ] **Analytics**
  - [ ] View dashboard metrics
  - [ ] Check sales reports
  - [ ] Review customer analytics

### 📱 Device & Performance Testing

- [ ] **Android Testing**
  - [ ] Test on Android 7+ (API 24+)
  - [ ] Test on small screen (5")
  - [ ] Test on tablet
  - [ ] Test in landscape mode
  - [ ] Verify back button behavior

- [ ] **iOS Testing**
  - [ ] Test on iPhone (various sizes)
  - [ ] Test on iPad
  - [ ] Verify permissions prompts
  - [ ] Test on iOS 12+

- [ ] **Performance**
  - [ ] App launches in < 3 seconds
  - [ ] Smooth scrolling in lists
  - [ ] Images load quickly
  - [ ] No memory leaks after 10 min use
  - [ ] Battery usage is reasonable

### 🌐 Network & Offline Testing

- [ ] **Online Mode**
  - [ ] All API calls work correctly
  - [ ] Error messages for failed requests
  - [ ] Timeout handling (30s)

- [ ] **Offline Mode**
  - [ ] App doesn't crash when offline
  - [ ] Shows cached data where available
  - [ ] Clear offline indicators
  - [ ] Queues actions for when online

- [ ] **Poor Network**
  - [ ] Test on 3G connection
  - [ ] Test with network throttling
  - [ ] Verify timeout messages

### 🔔 Notifications & Permissions

- [ ] **Permissions**
  - [ ] Location permission request
  - [ ] Camera permission (photo upload)
  - [ ] Notification permission
  - [ ] Proper explanations shown

- [ ] **Notifications**
  - [ ] Favorite truck nearby
  - [ ] Schedule updates
  - [ ] Review responses
  - [ ] Can disable in settings

### 🎨 UI/UX Testing

- [ ] **Visual**
  - [ ] Consistent theming
  - [ ] Dark mode support
  - [ ] Proper text contrast
  - [ ] Touch targets ≥ 48dp
  - [ ] Loading states everywhere

- [ ] **Accessibility**
  - [ ] Screen reader compatible
  - [ ] Proper content descriptions
  - [ ] Keyboard navigation (if applicable)

### 🐛 Edge Cases

- [ ] **Data Validation**
  - [ ] Very long text inputs
  - [ ] Special characters in names
  - [ ] Invalid email formats
  - [ ] Extreme GPS coordinates

- [ ] **Error Scenarios**
  - [ ] Server returns 500 error
  - [ ] Malformed JSON response
  - [ ] Expired auth token
  - [ ] Rate limiting

### 📊 Analytics Verification

- [ ] **Events Tracking**
  - [ ] App opens logged
  - [ ] Screen views tracked
  - [ ] User actions recorded
  - [ ] Crashes reported

### 🚀 Production Build

- [ ] **Build Process**
  ```bash
  # Create .env.production from template
  cp .env.production.template .env.production
  # Add your API keys
  # Run production build
  ./build_production.sh
  ```

- [ ] **Final Checks**
  - [ ] No debug logs in release build
  - [ ] ProGuard/R8 not breaking functionality
  - [ ] App size < 100MB
  - [ ] Signing certificate correct

### 📝 Store Submission Prep

- [ ] **Assets Ready**
  - [ ] App icon (512x512)
  - [ ] Screenshots (various devices)
  - [ ] Feature graphic
  - [ ] Privacy policy URL
  - [ ] App description

- [ ] **Compliance**
  - [ ] COPPA compliance
  - [ ] GDPR compliance
  - [ ] Location usage justification
  - [ ] Background location explanation

## Testing Sign-Off

- [ ] All critical paths tested
- [ ] No crashes during testing
- [ ] Performance acceptable
- [ ] Security measures in place
- [ ] Ready for production! 🎉

---

**Testing Environment:**
- Devices tested: ________________
- OS versions: ________________
- Tester name: ________________
- Date: ________________