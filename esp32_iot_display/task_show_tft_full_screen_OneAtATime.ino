/**********************************************************************
 * ESP32-S3 Task Manager Display (Buddy OS Edition)
 * * Fetches the dashboard document from Firestore and displays tasks
 * on an ST7789 TFT (240x320) full-screen, one task at a time.
 * Cycles every 8 seconds.
 *
 * Hardware:
 * - ESP32 / ESP32-S3
 * - ST7789 TFT 240x320 (SPI)
 *
 * Required Arduino libraries (install via Library Manager):
 * - ArduinoJson      by Benoit Blanchon
 * - Adafruit GFX     by Adafruit
 * - Adafruit ST7735 and ST7789 Library by Adafruit
 **********************************************************************/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <SPI.h>

// ══════════════════════════════════════════════════════════════════════
//  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════

// WiFi
const char* WIFI_SSID     = "Pi";
const char* WIFI_PASSWORD = "12345678";

// Firebase Web API Key & Project ID
const char* FIREBASE_API_KEY   = "AIzaSyBnBnlF8rFsTumxq8v6uaru5hxSv5K0sBw";
const char* FIREBASE_PROJECT_ID = "buddy-a4902";

// Auth credentials (Firebase user that owns the tasks)
const char* AUTH_EMAIL    = "user1@gmail.com";
const char* AUTH_PASSWORD = "12345678";

// TFT Display (ST7789 240x320, SPI)
#define TFT_CS   10
#define TFT_DC    8
#define TFT_RST   9
#define TFT_MOSI 11
#define TFT_SCLK 12

#define TFT_WIDTH  240
#define TFT_HEIGHT 320

// Custom Colors (RGB565)
#define COLOR_BG      0x0000 // Black
#define COLOR_CYAN    0x07FF // Cyan accent
#define COLOR_HEADER  0x18E3 // Dark Gray/Blue
#define COLOR_TEXT    0xFFFF // White

// Poll interval (seconds between Firestore refreshes)
#define POLL_INTERVAL_SEC 30

// NTP
const char* NTP_SERVER   = "pool.ntp.org";
const int   GMT_OFFSET   = 0;
const int   DAYLIGHT_OFFSET = 0;

// ══════════════════════════════════════════════════════════════════════
//  GLOBALS
// ══════════════════════════════════════════════════════════════════════

Adafruit_ST7789 display = Adafruit_ST7789(TFT_CS, TFT_DC, TFT_RST);
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

// Pagination & Rotation Variables
const int TASK_DISPLAY_TIME_MS = 8000; // 8 Seconds per task page
unsigned long lastTaskSwitch = 0;
int currentSection = 0;
int currentTaskIndex = 0;

int previousRenderedSection = -1; 
int previousRenderedTask = -1;
unsigned long lastClockUpdate = 0;

// Page Tracking Variables
int currentTaskPage = 0;
int totalTaskPages = 1;
unsigned long taskPageTimer = 0;
const int PAGE_JUMP_PIXELS = 180; // Pixels to shift text per page (allows overlap to keep reading context)

struct SectionInfo { 
  String title; 
  const TaskItem* items; 
  int count; 
};

// ── Forward Declarations ─────────────────────────────────────────────
bool connectWiFi();
bool fetchIdToken();
bool fetchDashboard();
void parseFirestoreDocument(const String& json, DashboardData& out);
void showBootAnimation();
void updateBootStatus(const String& step, int progress);
void showError(const String& msg);
int  getActiveSections(SectionInfo sections[]);
void advanceTask(SectionInfo activeSections[], int numSections);
void renderCurrentTask(SectionInfo activeSections[], int numSections);
void drawTaskUI(const String& secTitle, const TaskItem& task, int currentNum, int totalNum, int scrollY, bool fullRedraw);
int  getTextHeight(const String& text, int x, int textSize);
int  printWrappedTextWithClip(const String& text, int x, int y, int textSize, uint16_t color, int minY, int maxY);
void drawEmptyScreen();
void updateClock();

// ══════════════════════════════════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(100);
  Serial.println(F("\n--- BUDDY OS TASK CORE V2.1 BOOTING ---"));

  SPI.begin(TFT_SCLK, -1, TFT_MOSI, TFT_CS);
  display.init(240, 320);
  display.setRotation(0); 
  display.setTextWrap(false); 
  
  showBootAnimation();
  client.setInsecure();

  updateBootStatus("Connecting WiFi...", 30);
  if (!connectWiFi()) {
    showError("WiFi failed");
    return;
  }

  updateBootStatus("Syncing Time...", 50);
  Serial.println(F("Syncing time via NTP..."));
  configTime(GMT_OFFSET * 3600, DAYLIGHT_OFFSET * 3600, NTP_SERVER);

  updateBootStatus("Authenticating User...", 70);
  if (!fetchIdToken()) {
    showError("Auth failed");
    return;
  }

  updateBootStatus("Loading Dashboard...", 90);
  if (!fetchDashboard()) {
    showError("Fetch failed");
    return;
  }

  updateBootStatus("System Ready", 100);
  Serial.println(F("System Boot Complete. Entering Main Loop."));
  delay(500);
  display.fillScreen(COLOR_BG); 
}

// ══════════════════════════════════════════════════════════════════════
//  LOOP
// ══════════════════════════════════════════════════════════════════════
void loop() {
  unsigned long now = millis();

  // Handle data fetching
  if (now - lastFetch > POLL_INTERVAL_SEC * 1000UL) {
    lastFetch = now;
    if (WiFi.status() != WL_CONNECTED) connectWiFi();
    if (idToken.isEmpty() || now > tokenExpiry) fetchIdToken();
    if (!idToken.isEmpty()) fetchDashboard();
  }

  // Identify which sections have items
  SectionInfo activeSections[3];
  int numSections = getActiveSections(activeSections);

  if (numSections > 0) {
    // Safety check in case a refresh reduced the active sections/counts
    if (currentSection >= numSections) {
        currentSection = 0;
        currentTaskIndex = 0;
    } else if (currentTaskIndex >= activeSections[currentSection].count) {
        currentTaskIndex = 0;
    }
    
    // The task advancing is now handled dynamically inside renderCurrentTask
    renderCurrentTask(activeSections, numSections);
  } else {
    // Draw empty state
    if (previousRenderedSection != -1) {
        display.fillScreen(COLOR_BG);
        previousRenderedSection = -1;
        previousRenderedTask = -1;
        drawEmptyScreen();
    }
    updateClock(); // Keep clock running
  }
  
  delay(15); 
}

// ══════════════════════════════════════════════════════════════════════
//  RENDER ENGINE (Full Screen One-By-One)
// ══════════════════════════════════════════════════════════════════════

// Populates the sections array based on the displayMode and valid counts
int getActiveSections(SectionInfo sections[]) {
  int count = 0;
  if (dashboard.displayMode == "rotate") {
     if (dashboard.todayCount > 0) sections[count++] = {"Today", dashboard.today, dashboard.todayCount};
     if (dashboard.dailyCount > 0) sections[count++] = {"Daily", dashboard.daily, dashboard.dailyCount};
     if (dashboard.constantCount > 0) sections[count++] = {"Constant", dashboard.constant, dashboard.constantCount};
  } else if (dashboard.displayMode == "today" && dashboard.todayCount > 0) {
     sections[count++] = {"Today", dashboard.today, dashboard.todayCount};
  } else if (dashboard.displayMode == "daily" && dashboard.dailyCount > 0) {
     sections[count++] = {"Daily", dashboard.daily, dashboard.dailyCount};
  } else if (dashboard.displayMode == "constant" && dashboard.constantCount > 0) {
     sections[count++] = {"Constant", dashboard.constant, dashboard.constantCount};
  }
  return count;
}

void advanceTask(SectionInfo activeSections[], int numSections) {
   currentTaskIndex++;
   if (currentTaskIndex >= activeSections[currentSection].count) {
      currentTaskIndex = 0;
      if (dashboard.displayMode == "rotate") {
         currentSection = (currentSection + 1) % numSections;
      }
   }
}

void renderCurrentTask(SectionInfo activeSections[], int numSections) {
  int secIdx = currentSection;
  int taskIdx = currentTaskIndex;
  const TaskItem& task = activeSections[secIdx].items[taskIdx];

  // 1. New Task Trigger: Evaluate height and setup scene
  if (previousRenderedSection != secIdx || previousRenderedTask != taskIdx) {
     previousRenderedSection = secIdx;
     previousRenderedTask = taskIdx;
     
     // Calculate pixel height of text
     int titleH = getTextHeight(task.text, 35, 3);
     int descH = task.description.length() > 0 ? 15 + getTextHeight(task.description, 35, 2) : 0;
     int totalH = titleH + descH;
     
     // Available drawing space between header and footer
     int availableH = TFT_HEIGHT - 30 - 25 - 40; 
     
     // Determine if pagination is needed
     if (totalH > availableH) {
         totalTaskPages = 1 + ((totalH - availableH + PAGE_JUMP_PIXELS - 1) / PAGE_JUMP_PIXELS);
     } else {
         totalTaskPages = 1;
     }
     
     currentTaskPage = 0;
     taskPageTimer = millis();
     
     // Draw the whole screen structure once
     drawTaskUI(activeSections[secIdx].title, task, taskIdx + 1, activeSections[secIdx].count, 0, true);
  } 
  // 2. Active Task State Machine (Pagination mode)
  else {
     unsigned long elapsed = millis() - taskPageTimer;
     
     if (elapsed > TASK_DISPLAY_TIME_MS) {
         if (currentTaskPage < totalTaskPages - 1) {
             // Flip to the next page
             currentTaskPage++;
             taskPageTimer = millis();
             int scrollY = currentTaskPage * PAGE_JUMP_PIXELS;
             
             // Redraw only the text body zone using our page offset
             drawTaskUI(activeSections[secIdx].title, task, taskIdx + 1, activeSections[secIdx].count, scrollY, false);
         } else {
             // Finished all pages, move to next task
             advanceTask(activeSections, numSections);
         }
     }
  }

  // Independent clock update so time doesn't freeze
  if (millis() - lastClockUpdate > 1000) {
     lastClockUpdate = millis();
     updateClock();
  }
}

void drawTaskUI(const String& secTitle, const TaskItem& task, int currentNum, int totalNum, int scrollY, bool fullRedraw) {
  int headerHeight = 30;
  int footerHeight = 25;
  int bodyMinY = headerHeight + 1;
  int bodyMaxY = TFT_HEIGHT - footerHeight - 1;

  if (fullRedraw) {
      display.fillScreen(COLOR_BG);
      
      // --- HEADER ---
      display.fillRect(0, 0, TFT_WIDTH, headerHeight, COLOR_HEADER); 
      display.setTextSize(2);
      display.setTextColor(COLOR_CYAN);
      display.setCursor(8, 7);
      display.print(secTitle);
      
      String progress = String(currentNum) + "/" + String(totalNum);
      int progWidth = progress.length() * 12; 
      display.setCursor(TFT_WIDTH - progWidth - 8, 7);
      display.setTextColor(COLOR_TEXT);
      display.print(progress);
      
      display.drawFastHLine(0, headerHeight, TFT_WIDTH, COLOR_CYAN);
    
      // --- FOOTER ---
      int footerY = TFT_HEIGHT - footerHeight;
      display.fillRect(0, footerY, TFT_WIDTH, footerHeight, COLOR_HEADER); 
      display.drawFastHLine(0, footerY, TFT_WIDTH, COLOR_CYAN);
      
      display.setTextSize(1);
      display.setTextColor(COLOR_TEXT);
      display.setCursor(8, footerY + 8);
      display.print(dashboard.generatedDate.isEmpty() ? "Loading..." : dashboard.generatedDate);
      
      updateClock();
  }

  // --- BODY (Full Screen Task) ---
  // Only clear the middle area to prevent flickering the whole screen when turning a page
  if (!fullRedraw) {
      display.fillRect(0, bodyMinY, TFT_WIDTH, bodyMaxY - bodyMinY, COLOR_BG);
  }

  int startY = headerHeight + 25 - scrollY;
  
  // Draw modern bullet point identifier (Manually clipped)
  if (startY + 2 > bodyMinY && startY + 10 < bodyMaxY) {
      display.fillRoundRect(15, startY + 2, 8, 8, 2, COLOR_CYAN);
  }

  // Text wrapper creates beautiful paragraphs and handles clipping boundaries for pagination
  int descY = printWrappedTextWithClip(task.text, 35, startY, 3, COLOR_TEXT, bodyMinY, bodyMaxY);

  if (task.description.length() > 0) {
     descY += 15;
     if (descY - 8 > bodyMinY && descY - 8 < bodyMaxY) {
         display.drawFastHLine(35, descY - 8, 50, display.color565(80, 80, 80)); 
     }
     printWrappedTextWithClip(task.description, 35, descY, 2, display.color565(180, 180, 180), bodyMinY, bodyMaxY);
  }
}

// Calculates spatial pixel height needed for a text block without actually drawing it
int getTextHeight(const String& text, int x, int textSize) {
   if (text.isEmpty()) return 0;
   int charWidth = textSize * 6;
   int maxCharsPerLine = (TFT_WIDTH - x - 10) / charWidth;
   int lineHeight = (textSize * 8) + 4;
   
   String currentLine = "";
   int startIdx = 0;
   int currentY = 0;
   
   while (startIdx < text.length()) {
      int spaceIdx = text.indexOf(' ', startIdx);
      String word = "";
      if (spaceIdx == -1) {
         word = text.substring(startIdx);
         startIdx = text.length();
      } else {
         word = text.substring(startIdx, spaceIdx + 1);
         startIdx = spaceIdx + 1;
      }
      if (currentLine.length() + word.length() > maxCharsPerLine) {
         currentY += lineHeight;
         if (word.startsWith(" ")) word = word.substring(1);
         currentLine = word;
      } else {
         currentLine += word;
      }
   }
   if (currentLine.length() > 0) currentY += lineHeight;
   return currentY;
}

// Custom wrapper logic that prevents Adafruit GFX text bleed into header/footer when paginating/scrolling
int printWrappedTextWithClip(const String& text, int x, int y, int textSize, uint16_t color, int minY, int maxY) {
   display.setTextSize(textSize);
   display.setTextColor(color);
   
   int charWidth = textSize * 6;
   int maxCharsPerLine = (TFT_WIDTH - x - 10) / charWidth; 
   int lineHeight = (textSize * 8) + 4;
   
   String currentLine = "";
   int startIdx = 0;
   int currentY = y;
   
   while (startIdx < text.length()) {
      int spaceIdx = text.indexOf(' ', startIdx);
      String word = "";
      if (spaceIdx == -1) {
         word = text.substring(startIdx);
         startIdx = text.length();
      } else {
         word = text.substring(startIdx, spaceIdx + 1); 
         startIdx = spaceIdx + 1;
      }
      
      if (currentLine.length() + word.length() > maxCharsPerLine) {
         // Only physically draw if inside screen safe-zone
         if (currentY + lineHeight > minY && currentY < maxY) {
             display.setCursor(x, currentY);
             display.print(currentLine);
         }
         currentY += lineHeight; 
         
         if (word.startsWith(" ")) word = word.substring(1); 
         currentLine = word;
      } else {
         currentLine += word;
      }
   }
   if (currentLine.length() > 0) {
      if (currentY + lineHeight > minY && currentY < maxY) {
          display.setCursor(x, currentY);
          display.print(currentLine);
      }
      currentY += lineHeight; 
   }
   
   return currentY; 
}

void drawEmptyScreen() {
  int headerHeight = 30;
  int footerHeight = 25;
  
  display.fillRect(0, 0, TFT_WIDTH, headerHeight, COLOR_HEADER); 
  display.setTextSize(2);
  display.setTextColor(COLOR_CYAN);
  display.setCursor(8, 7);
  display.print("Tasks");
  display.drawFastHLine(0, headerHeight, TFT_WIDTH, COLOR_CYAN);
  
  display.setCursor(30, headerHeight + 50);
  display.setTextColor(display.color565(150, 150, 150), COLOR_BG);
  display.setTextSize(2);
  display.print(F("No tasks right now."));
  display.setCursor(30, headerHeight + 75);
  display.setTextSize(1);
  display.print(F("Enjoy your free time!"));

  int footerY = TFT_HEIGHT - footerHeight;
  display.fillRect(0, footerY, TFT_WIDTH, footerHeight, COLOR_HEADER); 
  display.drawFastHLine(0, footerY, TFT_WIDTH, COLOR_CYAN);
  
  display.setTextSize(1);
  display.setTextColor(COLOR_TEXT);
  display.setCursor(8, footerY + 8);
  display.print(dashboard.generatedDate.isEmpty() ? "Loading..." : dashboard.generatedDate);
}

void updateClock() {
  int footerHeight = 25;
  int footerY = TFT_HEIGHT - footerHeight;
  struct tm timeinfo;
  
  if (getLocalTime(&timeinfo)) {
    char buf[12];
    strftime(buf, sizeof(buf), "%H:%M", &timeinfo);
    
    // Fill over the previous clock characters exactly to avoid flickering the whole footer
    display.fillRect(170, footerY + 1, 70, footerHeight - 2, COLOR_HEADER);
    
    display.setTextSize(2);
    display.setTextColor(COLOR_CYAN);
    display.setCursor(170, footerY + 5);
    display.print(buf);
  }
}

// ══════════════════════════════════════════════════════════════════════
//  BOOT ANIMATION & UI HELPERS
// ══════════════════════════════════════════════════════════════════════
void showBootAnimation() {
  display.fillScreen(COLOR_BG);
  display.setTextSize(3);
  display.setTextColor(COLOR_CYAN);
  display.setCursor(45, 100);
  display.print("BUDDY OS");

  display.setTextSize(1);
  display.setTextColor(COLOR_TEXT);
  display.setCursor(68, 135);
  display.print("TASK CORE V2.1");

  for(int i=0; i<110; i+=5) {
    display.drawRect(120 - i, 160, i * 2, 2, COLOR_CYAN);
    delay(10);
  }
}

void updateBootStatus(const String& step, int progress) {
  display.fillRect(0, 200, TFT_WIDTH, 40, COLOR_BG);
  display.setTextSize(1);
  display.setTextColor(COLOR_TEXT);
  int cursorX = (TFT_WIDTH - (step.length() * 6)) / 2;
  display.setCursor(cursorX, 210);
  display.print(step);

  int barWidth = 160;
  int barX = (TFT_WIDTH - barWidth) / 2;
  display.drawRect(barX, 230, barWidth, 10, COLOR_TEXT);
  int fillWidth = (barWidth * progress) / 100;
  display.fillRect(barX + 2, 232, fillWidth - 4, 6, COLOR_CYAN);
}

void showError(const String& msg) {
  display.fillScreen(COLOR_BG);
  display.drawRect(4, 4, TFT_WIDTH - 8, TFT_HEIGHT - 8, display.color565(255, 0, 0)); 
  display.setTextSize(2);
  display.setTextColor(display.color565(255, 0, 0));
  display.setCursor(20, 40);
  display.print(F("SYSTEM ERROR"));
  display.drawFastHLine(20, 65, TFT_WIDTH - 40, COLOR_TEXT);
  display.setTextSize(1);
  display.setTextColor(COLOR_TEXT);
  display.setCursor(20, 80);
  display.print(msg);
}

// ══════════════════════════════════════════════════════════════════════
//  FIREBASE & WIFI CORE
// ══════════════════════════════════════════════════════════════════════

bool connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    attempts++;
  }
  return (WiFi.status() == WL_CONNECTED);
}

bool fetchIdToken() {
  String path = String(F("/v1/accounts:signInWithPassword?key=")) + FIREBASE_API_KEY;
  String body = String(F("{\"email\":\"")) + AUTH_EMAIL
              + F("\",\"password\":\"") + AUTH_PASSWORD
              + F("\",\"returnSecureToken\":true}");

  if (!client.connect("identitytoolkit.googleapis.com", 443)) return false;

  client.println(String(F("POST ")) + path + F(" HTTP/1.0"));
  client.println(F("Host: identitytoolkit.googleapis.com"));
  client.println(F("Content-Type: application/json"));
  client.print(F("Content-Length: "));
  client.println(body.length());
  client.println();
  client.print(body);

  while (client.connected()) {
    if (client.readStringUntil('\n') == "\r") break; 
  }

  String response = client.readString(); 
  client.stop();

  JsonDocument doc;
  if (deserializeJson(doc, response) || doc["error"].is<JsonObject>()) return false;

  idToken = doc["idToken"].as<String>();
  firebaseUid = doc["localId"].as<String>();
  tokenExpiry = millis() + (doc["expiresIn"].as<int>() - 60) * 1000UL;
  return true;
}

bool fetchDashboard() {
  if (firebaseUid.isEmpty()) return false;

  String path = String(F("/v1/projects/")) + FIREBASE_PROJECT_ID
              + F("/databases/(default)/documents/users/") + firebaseUid
              + F("/dashboard/current");

  if (!client.connect("firestore.googleapis.com", 443)) return false;

  client.println(String(F("GET ")) + path + F(" HTTP/1.0"));
  client.println(F("Host: firestore.googleapis.com"));
  client.print(F("Authorization: Bearer "));
  client.println(idToken);
  client.println(F("Accept: application/json"));
  client.println();

  while (client.connected()) {
    if (client.readStringUntil('\n') == "\r") break; 
  }

  String response = client.readString();
  client.stop();

  if (response.isEmpty() || response.startsWith("{\"error\"")) return false;
  
  parseFirestoreDocument(response, dashboard);
  return true;
}

void parseFirestoreDocument(const String& json, DashboardData& out) {
  JsonDocument doc;
  if (deserializeJson(doc, json)) return;

  JsonObject fields = doc["fields"];
  if (fields.isNull()) {
    JsonObject root = doc.as<JsonObject>();
    if (root["fields"].is<JsonObject>()) fields = root["fields"].as<JsonObject>();
  }
  if (fields.isNull()) return;

  out = DashboardData();
  out.rotationInterval = 15;

  auto readString = [&](const char* name) -> String {
    return fields[name].is<JsonObject>() ? fields[name]["stringValue"].as<String>() : "";
  };
  
  out.generatedDate = readString("generatedDate");
  out.displayMode   = readString("displayMode");

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