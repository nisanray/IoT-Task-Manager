/**********************************************************************
 * ESP32 IoT Task Manager Display
 * * Fetches the dashboard document from Firestore and displays tasks
 * on an SSD1306 OLED (128x64) with automatic section rotation.
 *
 * Hardware:
 * - ESP32 (any variant)
 * - SSD1306 OLED 128x64 (I2C: SDA=GPIO21, SCL=GPIO22)
 *
 * Required Arduino libraries (install via Library Manager):
 * - ArduinoJson        by Benoit Blanchon
 * - Adafruit GFX       by Adafruit
 * - Adafruit SSD1306   by Adafruit
 **********************************************************************/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ══════════════════════════════════════════════════════════════════════
//  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════

// WiFi
const char* WIFI_SSID     = "Wokwi-GUEST";
const char* WIFI_PASSWORD = "";

// Firebase Web API Key & Project ID (from firebase_options.dart)
const char* FIREBASE_API_KEY   = "AIzaSyBnBnlF8rFsTumxq8v6uaru5hxSv5K0sBw";
const char* FIREBASE_PROJECT_ID = "buddy-a4902";

// Auth credentials (Firebase user that owns the tasks)
const char* AUTH_EMAIL    = "user1@gmail.com";
const char* AUTH_PASSWORD = "12345678";

// OLED Display (SSD1306 128x64, I2C)
#define OLED_WIDTH  128
#define OLED_HEIGHT 64
#define OLED_ADDRESS 0x3C
#define OLED_SDA 8
#define OLED_SCL 9

// Poll interval (seconds between Firestore refreshes)
#define POLL_INTERVAL_SEC 30

// NTP
const char* NTP_SERVER   = "pool.ntp.org";
const int   GMT_OFFSET   = 0;
const int   DAYLIGHT_OFFSET = 0;

// ══════════════════════════════════════════════════════════════════════
//  GLOBALS
// ══════════════════════════════════════════════════════════════════════

Adafruit_SSD1306 display(OLED_WIDTH, OLED_HEIGHT, &Wire, -1);
WiFiClientSecure client;

String idToken = "";
String firebaseUid = "";
unsigned long tokenExpiry = 0;

struct TaskItem {
  String text;
  String description;
};

struct DashboardData {
  String  generatedDate;
  String  displayMode;
  int     rotationInterval;
  TaskItem today[20];
  int     todayCount;
  TaskItem daily[20];
  int     dailyCount;
  TaskItem constant[20];
  int     constantCount;
};

DashboardData dashboard;
unsigned long lastFetch = 0;
unsigned long lastSectionSwitch = 0;
int currentSection = 0;
int currentScrollOffset = 0;
unsigned long lastScroll = 0;

// ── Forward Declarations ─────────────────────────────────────────────
bool connectWiFi();
bool fetchIdToken();
bool fetchDashboard();
void parseFirestoreDocument(const String& json, DashboardData& out);
void displaySection(const String& title, const TaskItem items[], int count);
void showSplash();
void showError(const String& msg);
void renderCurrentSection();
String getMarqueeText(const String& original, int maxLen, unsigned long now);

// ══════════════════════════════════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(100);

  Wire.begin(OLED_SDA, OLED_SCL);
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    for (;;) delay(1000);
  }
  showSplash();

  client.setInsecure();

  if (!connectWiFi()) {
    showError("WiFi failed");
    return;
  }

  configTime(GMT_OFFSET * 3600, DAYLIGHT_OFFSET * 3600, NTP_SERVER);

  if (!fetchIdToken()) {
    showError("Auth failed");
    return;
  }
  if (!fetchDashboard()) {
    showError("Fetch failed");
    return;
  }
}

// ══════════════════════════════════════════════════════════════════════
//  LOOP
// ══════════════════════════════════════════════════════════════════════
void loop() {
  unsigned long now = millis();

  if (now - lastFetch > POLL_INTERVAL_SEC * 1000UL) {
    lastFetch = now;
    if (WiFi.status() != WL_CONNECTED) {
      connectWiFi();
    }
    if (idToken.isEmpty() || now > tokenExpiry) {
      fetchIdToken();
    }
    if (!idToken.isEmpty()) {
      fetchDashboard();
    }
  }

  int interval = (dashboard.rotationInterval > 0) ? dashboard.rotationInterval : 15;
  if (dashboard.displayMode == "rotate") {
    if (now - lastSectionSwitch > interval * 1000UL) {
      lastSectionSwitch = now;
      currentScrollOffset = 0;
      int totalSections = 0;
      if (dashboard.todayCount > 0) totalSections++;
      if (dashboard.dailyCount > 0) totalSections++;
      if (dashboard.constantCount > 0) totalSections++;
      if (totalSections > 0) {
        currentSection = (currentSection + 1) % totalSections;
      }
    }
  }

  renderCurrentSection();
  delay(100);
}

// ══════════════════════════════════════════════════════════════════════
//  RENDER
// ══════════════════════════════════════════════════════════════════════
void renderCurrentSection() {
  display.clearDisplay();

  String title = "Tasks";
  const TaskItem* items = nullptr;
  int count = 0;

  struct SectionInfo { String title; const TaskItem* items; int count; };
  SectionInfo sections[3];
  int secCount = 0;

  if (dashboard.todayCount > 0) {
    sections[secCount++] = {"Today", dashboard.today, dashboard.todayCount};
  }
  if (dashboard.dailyCount > 0) {
    sections[secCount++] = {"Daily", dashboard.daily, dashboard.dailyCount};
  }
  if (dashboard.constantCount > 0) {
    sections[secCount++] = {"Constant", dashboard.constant, dashboard.constantCount};
  }

  if (dashboard.displayMode == "rotate") {
    if (secCount > 0) {
      currentSection = constrain(currentSection, 0, secCount - 1);
      title  = sections[currentSection].title;
      items  = sections[currentSection].items;
      count  = sections[currentSection].count;
    }
  } else if (dashboard.displayMode == "today") {
    title = "Today"; items = dashboard.today; count = dashboard.todayCount;
  } else if (dashboard.displayMode == "daily") {
    title = "Daily"; items = dashboard.daily; count = dashboard.dailyCount;
  } else if (dashboard.displayMode == "constant") {
    title = "Constant"; items = dashboard.constant; count = dashboard.constantCount;
  }

  displaySection(title, items, count);
  display.display();
}

String getMarqueeText(const String& original, int maxLen, unsigned long now) {
  if (original.length() <= maxLen) {
    return original;
  }
  
  String scrollText = original + F("   ");
  int scrollTextLen = scrollText.length();
  int pauseSteps = 6;
  int totalSteps = scrollTextLen + pauseSteps;
  
  int step = (now / 300) % totalSteps;
  int offset = 0;
  if (step > pauseSteps) {
    offset = step - pauseSteps;
  }
  
  String part = scrollText.substring(offset, offset + maxLen);
  if (part.length() < maxLen) {
    part += scrollText.substring(0, maxLen - part.length());
  }
  return part;
}

void displaySection(const String& title, const TaskItem items[], int count) {
  // 1. Draw Header
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(2, 2);
  display.print(title);

  if (dashboard.displayMode == "rotate") {
    display.setCursor(96, 2);
    display.print(F("("));
    display.print(currentSection + 1);
    display.print(F("/"));
    int total = (dashboard.todayCount > 0) + (dashboard.dailyCount > 0) + (dashboard.constantCount > 0);
    display.print(total);
    display.print(F(")"));
  }
  display.drawFastHLine(0, 11, OLED_WIDTH, SSD1306_WHITE);

  // 2. Draw Body
  if (count == 0 || items == nullptr) {
    display.setCursor(16, 28);
    display.print(F("No tasks to show"));
  } else {
    int yStart = 14;
    int lineHeight = 9;
    int maxLines = 4; // We can show 4 tasks: y=14, 23, 32, 41

    if (count > maxLines) {
      unsigned long now = millis();
      if (now - lastScroll > 3000) {
        lastScroll = now;
        currentScrollOffset++;
        if (currentScrollOffset > count - maxLines) {
          currentScrollOffset = 0;
        }
      }
    } else {
      currentScrollOffset = 0;
    }

    int startIdx = constrain(currentScrollOffset, 0, max(0, count - maxLines));
    int endIdx = min(startIdx + maxLines, count);

    for (int i = startIdx; i < endIdx; i++) {
      int y = yStart + (i - startIdx) * lineHeight;
      
      // Draw Checkbox
      display.drawRect(2, y + 1, 6, 6, SSD1306_WHITE);

      String text = items[i].text;
      String desc = items[i].description;
      String disp = text;
      if (!desc.isEmpty()) {
        disp += " - " + desc;
      }

      int maxLen = (count > maxLines) ? 18 : 19;
      String dispMarquee = getMarqueeText(disp, maxLen, millis());

      display.setCursor(12, y);
      display.print(dispMarquee);
    }

    // Draw Scrollbar
    if (count > maxLines) {
      int trackHeight = 35; // y from 14 to 49
      int thumbHeight = max(6, trackHeight * maxLines / count);
      int thumbY = 14 + (trackHeight - thumbHeight) * currentScrollOffset / (count - maxLines);
      display.fillRect(125, thumbY, 3, thumbHeight, SSD1306_WHITE);
    }
  }

  // 3. Draw Footer
  display.drawFastHLine(0, 52, OLED_WIDTH, SSD1306_WHITE);
  display.setCursor(2, 55);
  display.print(dashboard.generatedDate);

  struct tm timeinfo;
  if (getLocalTime(&timeinfo)) {
    char buf[12];
    strftime(buf, sizeof(buf), "%H:%M", &timeinfo);
    display.setCursor(96, 55);
    display.print(buf);
  }
}

// ══════════════════════════════════════════════════════════════════════
//  FIREBASE AUTH (REST API)
// ══════════════════════════════════════════════════════════════════════
bool fetchIdToken() {
  String path = String(F("/v1/accounts:signInWithPassword?key=")) + FIREBASE_API_KEY;

  String body = String(F("{\"email\":\"")) + AUTH_EMAIL
              + F("\",\"password\":\"") + AUTH_PASSWORD
              + F("\",\"returnSecureToken\":true}");

  if (!client.connect("identitytoolkit.googleapis.com", 443)) {
    Serial.println(F("Auth: connection failed"));
    return false;
  }

  client.println(String(F("POST ")) + path + F(" HTTP/1.0"));
  client.println(F("Host: identitytoolkit.googleapis.com"));
  client.println(F("Content-Type: application/json"));
  client.print(F("Content-Length: "));
  client.println(body.length());
  client.println();
  client.print(body);

  while (client.connected()) {
    String line = client.readStringUntil('\n');
    if (line == "\r") {
      break; 
    }
  }

  String response = client.readString(); 
  client.stop();

  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, response);
  if (err) {
    Serial.print(F("Auth JSON: "));
    Serial.println(err.c_str());
    return false;
  }

  if (doc["error"].is<JsonObject>()) {
    Serial.print(F("Auth error: "));
    Serial.println(doc["error"]["message"].as<String>());
    return false;
  }

  idToken = doc["idToken"].as<String>();
  firebaseUid = doc["localId"].as<String>();
  int expiresIn = doc["expiresIn"].as<int>();
  tokenExpiry = millis() + (expiresIn - 60) * 1000UL;
  Serial.println(F("Auth OK"));
  return true;
}

// ══════════════════════════════════════════════════════════════════════
//  FIRESTORE (REST API)
// ══════════════════════════════════════════════════════════════════════
bool fetchDashboard() {
  if (firebaseUid.isEmpty()) {
    Serial.println(F("Firestore: no UID"));
    return false;
  }

  String path = String(F("/v1/projects/"))
              + FIREBASE_PROJECT_ID
              + F("/databases/(default)/documents/users/")
              + firebaseUid
              + F("/dashboard/current");

  if (!client.connect("firestore.googleapis.com", 443)) {
    Serial.println(F("Firestore: connection failed"));
    return false;
  }

  client.println(String(F("GET ")) + path + F(" HTTP/1.0"));
  client.println(F("Host: firestore.googleapis.com"));
  client.print(F("Authorization: Bearer "));
  client.println(idToken);
  client.println(F("Accept: application/json"));
  client.println();

  while (client.connected()) {
    String line = client.readStringUntil('\n');
    if (line == "\r") {
      break; 
    }
  }

  String response = client.readString();
  client.stop();

  if (response.isEmpty()) {
    Serial.println(F("Firestore: empty response"));
    return false;
  }

  if (response.startsWith("{\"error\"")) {
    Serial.print(F("Firestore error: "));
    Serial.println(response);
    return false;
  }

  parseFirestoreDocument(response, dashboard);
  Serial.println(F("Dashboard updated"));
  return true;
}

// ══════════════════════════════════════════════════════════════════════
//  FIRESTORE DOCUMENT PARSER
// ══════════════════════════════════════════════════════════════════════
void parseFirestoreDocument(const String& json, DashboardData& out) {
  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, json);
  if (err) {
    Serial.print(F("Parse: "));
    Serial.println(err.c_str());
    return;
  }

  JsonObject fields = doc["fields"];
  if (fields.isNull()) {
    JsonObject root = doc.as<JsonObject>();
    if (root["fields"].is<JsonObject>()) {
      fields = root["fields"].as<JsonObject>();
    }
  }

  if (fields.isNull()) {
    Serial.println(F("Parse: no fields"));
    return;
  }

  out = DashboardData();
  out.rotationInterval = 15;

  auto readString = [&](const char* name) -> String {
    if (!fields[name].is<JsonObject>()) return "";
    return fields[name]["stringValue"].as<String>();
  };
  auto readInt = [&](const char* name) -> int {
    if (!fields[name].is<JsonObject>()) return 0;
    JsonObject f = fields[name];
    if (f["integerValue"].is<const char*>()) return f["integerValue"].as<int>();
    return f["integerValue"].as<int>();
  };

  out.generatedDate     = readString("generatedDate");
  out.displayMode        = readString("displayMode");
  out.rotationInterval   = readInt("rotationInterval");
  if (out.rotationInterval < 5) out.rotationInterval = 15;

  auto readItems = [&](const char* name, TaskItem items[], int& count) {
    count = 0;
    JsonObject arrField = fields[name];
    if (arrField.isNull()) return;
    JsonArray values = arrField["arrayValue"]["values"];
    if (values.isNull()) return;
    for (JsonVariant v : values) {
      if (count >= 20) break;
      JsonObject mapField = v["mapValue"]["fields"];
      if (mapField.isNull()) continue;
      items[count].text = mapField["text"]["stringValue"].as<String>();
      if (mapField["description"].is<JsonObject>()) {
        items[count].description = mapField["description"]["stringValue"].as<String>();
      } else {
        items[count].description = "";
      }
      count++;
    }
  };

  readItems("today",    out.today,    out.todayCount);
  readItems("daily",    out.daily,    out.dailyCount);
  readItems("constant", out.constant, out.constantCount);
}

// ══════════════════════════════════════════════════════════════════════
//  WIFI
// ══════════════════════════════════════════════════════════════════════
bool connectWiFi() {
  Serial.print(F("Connecting to WiFi"));
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println(F("Connecting WiFi..."));
  display.display();

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    Serial.print(F("."));
    attempts++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print(F("IP: "));
    Serial.println(WiFi.localIP());
    return true;
  }

  Serial.println(F("WiFi failed"));
  return false;
}

// ══════════════════════════════════════════════════════════════════════
//  DISPLAY HELPERS
// ══════════════════════════════════════════════════════════════════════
void showSplash() {
  display.clearDisplay();
  display.drawRect(0, 0, OLED_WIDTH, OLED_HEIGHT, SSD1306_WHITE);
  display.drawRect(2, 2, OLED_WIDTH - 4, OLED_HEIGHT - 4, SSD1306_WHITE);
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  display.setCursor(12, 18);
  display.print(F("SMART TASK MANAGER"));
  
  display.setCursor(26, 38);
  display.print(F("Connecting..."));
  
  display.display();
}

void showError(const String& msg) {
  display.clearDisplay();
  display.drawRect(0, 0, OLED_WIDTH, OLED_HEIGHT, SSD1306_WHITE);
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(10, 10);
  display.print(F("SYSTEM ERROR"));
  display.drawFastHLine(10, 22, OLED_WIDTH - 20, SSD1306_WHITE);
  display.setCursor(10, 30);
  display.print(msg);
  display.display();
  Serial.print(F("Error: "));
  Serial.println(msg);
}