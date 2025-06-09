import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.westedgefamily.foodtruckfinder',
  appName: 'Food Truck Finder',
  webDir: 'build',
  server: {
    androidScheme: 'https'
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '#FF6B35',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#FF6B35'
    }
  },
  android: {
    allowMixedContent: true,
    captureInput: true
  }
};

export default config;
