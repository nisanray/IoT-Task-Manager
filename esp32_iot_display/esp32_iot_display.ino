/**********************************************************************
 * ESP32 IoT Task Manager Display
 * 
 * Fetches the dashboard document from Firestore and displays tasks
 * on an SSD1306 OLED (128x64) with automatic section rotation.
 *
 * Hardware:
 *   - ESP32 (any variant)
 *   - SSD1306 OLED 128x64 (I2C: SDA=GPIO21, SCL=GPIO22)
 *
 * Required Arduino libraries (install via Library Manager):
 *   - ArduinoJson          by Benoit Blanchon
 *   - Adafruit GFX         by Adafruit
 *   - Adafruit SSD1306     by Adafruit
 **********************************************************************/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "config.h"

// ── Display ──────────────────────────────────────────────────────────
Adafruit_SSD1306 display(OLED_WIDTH, OLED_HEIGHT, &Wire, -1);

// ── WiFi Client (TLS) ────────────────────────────────────────────────
WiFiClientSecure client;

// ── Auth ──────────────────────────────────────────────────────────────
String idToken = "";
String firebaseUid = "";
unsigned long tokenExpiry = 0;

// ── Dashboard Data ───────────────────────────────────────────────────
struct TaskItem {
  String text;
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
int currentSection = 0;     // 0=today, 1=daily, 2=constant
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

// ══════════════════════════════════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(100);

  // Init OLED
  Wire.begin(OLED_SDA, OLED_SCL);
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    for (;;) delay(1000);
  }
  showSplash();

  // Init WiFi client (skip cert verification for simplicity;
  // for production use a fingerprint or cert bundle)
  client.setInsecure();

  // Connect WiFi
  if (!connectWiFi()) {
    showError("WiFi failed");
    return;
  }

  // Init NTP
  configTime(GMT_OFFSET * 3600, DAYLIGHT_OFFSET * 3600, NTP_SERVER);

  // Initial data fetch
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

  // ── Periodic refresh ───────────────────────────────────────────────
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

  // ── Section rotation ───────────────────────────────────────────────
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

  // ── Render ─────────────────────────────────────────────────────────
  renderCurrentSection();
  delay(100);
}

// ══════════════════════════════════════════════════════════════════════
//  RENDER
// ══════════════════════════════════════════════════════════════════════
void renderCurrentSection() {
  display.clearDisplay();

  // Determine which section to show
  String title;
  const TaskItem* items = nullptr;
  int count = 0;

  // Build ordered list of non-empty sections
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
  } else if (dashboard.displayMode == "today" && dashboard.todayCount > 0) {
    title = "Today"; items = dashboard.today; count = dashboard.todayCount;
  } else if (dashboard.displayMode == "daily" && dashboard.dailyCount > 0) {
    title = "Daily"; items = dashboard.daily; count = dashboard.dailyCount;
  } else if (dashboard.displayMode == "constant" && dashboard.constantCount > 0) {
    title = "Constant"; items = dashboard.constant; count = dashboard.constantCount;
  }

  if (count == 0 || items == nullptr) {
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 28);
    display.println(F("  No tasks to show"));
    display.display();
    return;
  }

  displaySection(title, items, count);
  display.display();
}

void displaySection(const String& title, const TaskItem items[], int count) {
  // ── Header bar ───────────────────────────────────────────────────
  display.fillRect(0, 0, OLED_WIDTH, 10, SSD1306_WHITE);
  display.setTextSize(1);
  display.setTextColor(SSD1306_BLACK);
  display.setCursor(2, 1);
  display.print(title);

  // Show section indicator on the right
  if (dashboard.displayMode == "rotate") {
    display.setCursor(OLED_WIDTH - 30, 1);
    display.print(F("("));
    display.print(currentSection + 1);
    display.print(F("/"));
    int total = (dashboard.todayCount > 0) + (dashboard.dailyCount > 0) + (dashboard.constantCount > 0);
    display.print(total);
    display.print(F(")"));
  }

  // ── Connection / time row ────────────────────────────────────────
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 12);
  struct tm timeinfo;
  if (getLocalTime(&timeinfo)) {
    char buf[12];
    strftime(buf, sizeof(buf), "%H:%M", &timeinfo);
    display.print(buf);
  }
  display.print(F("  "));
  display.print(dashboard.generatedDate);

  // ── Task list ────────────────────────────────────────────────────
  int yStart = 24;
  int lineHeight = 10;
  int maxLines = (OLED_HEIGHT - yStart) / lineHeight;

  // Scroll if content exceeds display
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
    display.setCursor(0, y);
    display.print(F(" "));
    display.print(char(149)); // bullet
    display.print(F(" "));

    // Truncate long text
    String text = items[i].text;
    if (text.length() > 16) {
      text = text.substring(0, 15) + F("...");
    }
    display.print(text);
  }

  // ── Scroll indicator ─────────────────────────────────────────────
  if (count > maxLines) {
    int dotY = yStart + maxLines * lineHeight;
    int totalDots = min(count, 6);
    int activeDot = map(currentScrollOffset, 0, max(1, count - maxLines), 0, totalDots - 1);
    int dotX = OLED_WIDTH / 2 - (totalDots * 3) / 2;
    for (int d = 0; d < totalDots; d++) {
      display.fillCircle(dotX + d * 6, dotY + 2, (d == activeDot) ? 2 : 1,
                         d == activeDot ? SSD1306_WHITE : SSD1306_INVERSE);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════
//  FIREBASE AUTH (REST API)
// ══════════════════════════════════════════════════════════════════════
bool fetchIdToken() {
  String url = String(F("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=")) + FIREBASE_API_KEY;

  String body = String(F("{\"email\":\"")) + AUTH_EMAIL
              + F("\",\"password\":\"") + AUTH_PASSWORD
              + F("\",\"returnSecureToken\":true}");

  if (!client.connect("identitytoolkit.googleapis.com", 443)) {
    Serial.println(F("Auth: connection failed"));
    return false;
  }

  client.println(String(F("POST ")) + url + F(" HTTP/1.1"));
  client.println(F("Host: identitytoolkit.googleapis.com"));
  client.println(F("Content-Type: application/json"));
  client.print(F("Content-Length: "));
  client.println(body.length());
  client.println();
  client.print(body);

  // Read response
  String response;
  bool headersDone = false;
  unsigned long timeout = millis() + 5000;
  while (millis() < timeout) {
    while (client.available()) {
      String line = client.readStringUntil('\n');
      line.trim();
      if (!headersDone && line.isEmpty()) { headersDone = true; continue; }
      if (headersDone) response += line;
    }
    if (headersDone && !response.isEmpty()) break;
    delay(10);
  }
  client.stop();

  // Parse
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
  tokenExpiry = millis() + (expiresIn - 60) * 1000UL; // renew 1min early
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

  String url = String(F("https://firestore.googleapis.com/v1/projects/"))
             + FIREBASE_PROJECT_ID
             + F("/databases/(default)/documents/users/")
             + firebaseUid
             + F("/dashboard/current");

  if (!client.connect("firestore.googleapis.com", 443)) {
    Serial.println(F("Firestore: connection failed"));
    return false;
  }

  client.println(String(F("GET ")) + url + F(" HTTP/1.1"));
  client.println(F("Host: firestore.googleapis.com"));
  client.print(F("Authorization: Bearer "));
  client.println(idToken);
  client.println(F("Accept: application/json"));
  client.println();

  // Read response
  String response;
  bool headersDone = false;
  unsigned long timeout = millis() + 8000;
  while (millis() < timeout) {
    while (client.available()) {
      String line = client.readStringUntil('\n');
      line.trim();
      if (!headersDone && line.isEmpty()) { headersDone = true; continue; }
      if (headersDone) response += line;
    }
    if (headersDone && !response.isEmpty()) break;
    delay(10);
  }
  client.stop();

  if (response.isEmpty()) {
    Serial.println(F("Firestore: empty response"));
    return false;
  }

  // Check for HTTP error
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

  // Fields are nested under "fields"
  JsonObject fields = doc["fields"];
  if (fields.isNull()) {
    // Try "fields" at root level (Firestore Document format)
    JsonObject root = doc.as<JsonObject>();
    if (root["fields"].is<JsonObject>()) {
      fields = root["fields"].as<JsonObject>();
    }
  }

  if (fields.isNull()) {
    Serial.println(F("Parse: no fields"));
    return;
  }

  // Reset
  out = DashboardData();
  out.rotationInterval = 15;

  // ── Scalar fields ──────────────────────────────────────────────────
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

  // ── Array fields ──────────────────────────────────────────────────
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
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(10, 10);
  display.println(F("Smart Task"));
  display.setCursor(10, 20);
  display.println(F("Manager"));
  display.setCursor(10, 40);
  display.setTextSize(1);
  display.println(F("Connecting..."));
  display.display();
}

void showError(const String& msg) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println(F("Error:"));
  display.println(msg);
  display.display();
  Serial.print(F("Error: "));
  Serial.println(msg);
}
