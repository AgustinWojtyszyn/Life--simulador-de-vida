import type { CapacitorConfig } from '@capacitor/cli';
const config: CapacitorConfig = { appId: 'com.agustinwojtyszyn.vida', appName: 'VIDA', webDir: 'dist', android: { backgroundColor: '#152b36' }, plugins: { StatusBar: { style: 'LIGHT', backgroundColor: '#152b36' }, SplashScreen: { launchShowDuration: 1200, backgroundColor: '#152b36' } } };
export default config;
