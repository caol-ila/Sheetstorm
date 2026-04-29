import { CapacitorConfig } from '@capacitor/cli';

/**
 * Sheetstorm Capacitor-Konfiguration
 *
 * Dev: server.url auf den lokalen Blazor-Dev-Server zeigen (siehe SHEETSTORM_DEV_URL).
 * Prod: webDir = 'www' enthält ein statisches HTML-Splash, das die Prod-PWA-URL lädt.
 */
const devUrl = process.env.SHEETSTORM_DEV_URL;

const config: CapacitorConfig = {
  appId: 'de.sheetstorm.app',
  appName: 'Sheetstorm',
  webDir: 'www',
  server: devUrl ? {
    url: devUrl,
    cleartext: devUrl.startsWith('http://'),
  } : undefined,
  plugins: {
    BluetoothLe: { displayStrings: { scanning: 'Suche Mitspieler …' } },
    PushNotifications: { presentationOptions: ['badge', 'sound', 'alert'] },
  },
};

export default config;
