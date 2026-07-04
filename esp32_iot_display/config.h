#ifndef CONFIG_H
#define CONFIG_H

// ═══════════════════════════════════════════════════════
//  WiFi Configuration
// ═══════════════════════════════════════════════════════
const char* WIFI_SSID     = "your_wifi_ssid";
const char* WIFI_PASSWORD = "your_wifi_password";

// ═══════════════════════════════════════════════════════
//  Firebase Configuration
// ═══════════════════════════════════════════════════════
// Find these in your Firebase console:
//   Project Settings → General → Web API Key
//   Project Settings → General → Project ID
const char* FIREBASE_API_KEY   = "your_firebase_web_api_key";
const char* FIREBASE_PROJECT_ID = "your_firebase_project_id";

// ═══════════════════════════════════════════════════════
//  Authentication Credentials
// ═══════════════════════════════════════════════════════
// The email/password of the account that owns the tasks.
// This is the same account used to sign into the Flutter app.
const char* AUTH_EMAIL    = "your_email@example.com";
const char* AUTH_PASSWORD = "your_password";

// ═══════════════════════════════════════════════════════
//  OLED Display Configuration (SSD1306)
// ═══════════════════════════════════════════════════════
#define OLED_WIDTH  128
#define OLED_HEIGHT 64
#define OLED_ADDRESS 0x3C
// Typical I2C pins for ESP32: SDA=GPIO21, SCL=GPIO22
// Change if your wiring is different:
#define OLED_SDA 21
#define OLED_SCL 22

// ═══════════════════════════════════════════════════════
//  Update Interval (seconds between Firestore polls)
// ═══════════════════════════════════════════════════════
#define POLL_INTERVAL_SEC 30

// ═══════════════════════════════════════════════════════
//  NTP Server (for accurate time on the display)
// ═══════════════════════════════════════════════════════
const char* NTP_SERVER   = "pool.ntp.org";
const int   GMT_OFFSET   = 0;     // UTC offset in hours
const int   DAYLIGHT_OFFSET = 0;  // daylight savings in hours

#endif
