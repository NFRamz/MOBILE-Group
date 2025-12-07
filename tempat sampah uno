#define BLYNK_PRINT Serial
#define BLYNK_TEMPLATE_ID "TMPL6RqbkOEfT"
#define BLYNK_TEMPLATE_NAME "Sampah1"
#define BLYNK_AUTH_TOKEN "a_689O4y7fgOKtwzqihc_ZP3c3qH2dnn"

#include <BlynkSimpleEsp32.h>
#include <ESP32Servo.h>
#include <HTTPClient.h>

#define VPIN_SENSOR_1       V0  
#define VPIN_SENSOR_2       V1  
#define VPIN_VOLUME         V2  
#define VPIN_SERVO_STATUS   V3  
#define VPIN_LED_HIJAU      V4  
#define VPIN_LED_KUNING     V5  
#define VPIN_LED_MERAH      V6  
#define VPIN_MODE_MANUAL    V7  
#define VPIN_MANUAL_SERVO   V8  
#define VPIN_MANUAL_BUZZER  V9  

String SUPABASE_URL  = "https://nuipcocgksncizoappww.supabase.co/rest/v1/sampah_logs";
String SUPABASE_KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51aXBjb2Nna3NuY2l6b2FwcHd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3MDkzOTcsImV4cCI6MjA3ODI4NTM5N30.ztYaunrT8xEU4Imf69FYCY74IAHjV252CW0UX__sC0Y";

const int trigPin_1  = 2;
const int echoPin_1  = 4;
const int trigPin_2  = 5;
const int echoPin_2  = 18;
const int ledHijau   = 23;        
const int ledKuning  = 22;       
const int ledMerah   = 21;       
const int buzzerPin  = 13;
const int servoPin   = 15;

const int tinggiTempatSampah = 11;
const int tinggiEfektif = 5;

//Variabel nama diDB
String DEVICE_NAME = "Sampah 1"; 

Servo myservo1;
BlynkTimer timer;

bool isServoOpen    = false;
bool manualMode     = false; 
bool notif80Sent    = false; 
bool notif90Sent    = false;

unsigned int duration_1, duration_2, jarak1, jarak2, volPersen;
unsigned long previousBuzzerTime = 0, startServoTime = 0;


unsigned long lastBlynkSend   = 0;
const long delay_kirimKeBlynk = 1000; 

int buzzerInterval = 30000;
int lastJarak1 = 0, lastJarak2 = 0, lastVolPersen = 0;

//untuk notif
unsigned long startTimer90 = 0;
unsigned long startTimer80 = 0;
bool isTimer90Running = false;
bool isTimer80Running = false;
int detikNotif = 10000;

char auth[] = BLYNK_AUTH_TOKEN;
char ssid[] = "KM8";      
char pass[] = "Mi_NFR51";

void setup() {
  Serial.begin(115200);
  
  pinMode(echoPin_1, INPUT);
  pinMode(echoPin_2, INPUT);
  pinMode(trigPin_1, OUTPUT);
  pinMode(trigPin_2, OUTPUT);
  pinMode(ledHijau, OUTPUT);
  pinMode(ledKuning, OUTPUT);
  pinMode(ledMerah, OUTPUT);
  pinMode(buzzerPin, OUTPUT);
  
  digitalWrite(ledHijau, LOW);
  digitalWrite(ledKuning, LOW);
  digitalWrite(ledMerah, LOW);
  digitalWrite(buzzerPin, LOW);
  
  myservo1.attach(servoPin);
  myservo1.write(0);
  
  Blynk.begin(auth, ssid, pass);

  // --- INTERVAL ---
  timer.setInterval(200L, runControlLogic); 
  timer.setInterval(2000L, sendToBlynk);     
  timer.setInterval(200L, sendToSupabase);
}

void loop() {
  Blynk.run(); 
  timer.run();
}

void runControlLogic() {
  readSensor_1(); 
  readSensor_2(); 
  
  if (!manualMode) {
    kontrolServoSimple(); 
    kontrolLEDBuzzerAuto();
  }
  checkNotifications();
}

void readSensor_1() {
  digitalWrite(trigPin_1, LOW); delayMicroseconds(2);
  digitalWrite(trigPin_1, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin_1, LOW);
  
  duration_1 = pulseIn(echoPin_1, HIGH, 10000); 
  if (duration_1 == 0) {
    jarak1 = 100; 
  }
  else {
    jarak1 = (duration_1 / 2) / 28.5;
  }
  lastJarak1 = jarak1;
}

void readSensor_2() {
  digitalWrite(trigPin_2, LOW); delayMicroseconds(2);
  digitalWrite(trigPin_2, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin_2, LOW);
  
  duration_2 = pulseIn(echoPin_2, HIGH, 10000);
  if (duration_2 == 0) {
    jarak2 = tinggiTempatSampah; 
  }
  else {
    jarak2 = (duration_2 / 2) / 28.5;
  }

  if (jarak2 > tinggiTempatSampah) {
    jarak2 = tinggiTempatSampah;
  }

  float tinggiSampahSaatIni = tinggiTempatSampah - jarak2;
  
  if (tinggiSampahSaatIni < 0) tinggiSampahSaatIni = 0;
  
  volPersen = (tinggiSampahSaatIni * 100) / tinggiEfektif;
  
  if (volPersen > 100) {
    volPersen = 100;
  }

  lastJarak2 = jarak2;
  lastVolPersen = volPersen;
}

void kontrolServoSimple() {
  unsigned long currentMillis = millis();


  if (!isServoOpen && jarak1 <= 30 && jarak1 > 1 && volPersen < 95) {
      Serial.println("Gerakan Otomatis Terdeteksi...");
      
      isServoOpen = true;             
      startServoTime = currentMillis; 
      
      myservo1.write(180);            
      Serial.println("Servo(180)");
  }


  if (isServoOpen) {
      unsigned long durasiBerjalan = currentMillis - startServoTime;

      if (durasiBerjalan >= 3000 && durasiBerjalan < 5000) {
          myservo1.write(100); 
      }
      

      else if (durasiBerjalan >= 5000) {
          myservo1.write(0);
          Serial.println("Servo(0) - Selesai");
          
          isServoOpen = false; 
      }
  }
}

void kontrolLEDBuzzerAuto() {
  unsigned long currentTime = millis();
  
  digitalWrite(ledHijau, LOW);
  digitalWrite(ledKuning, LOW);
  digitalWrite(ledMerah, LOW);
  
  if (volPersen < 70) {
    digitalWrite(ledHijau, HIGH);
    buzzerInterval = 0;
  } else if (volPersen >= 70 && volPersen < 90) {
    digitalWrite(ledKuning, HIGH);
    buzzerInterval = 3000;

    if (currentTime - previousBuzzerTime >= buzzerInterval) {
      bunyiBuzzer(2);
      previousBuzzerTime = currentTime;
    }
  } else if (volPersen >= 90) {
    digitalWrite(ledMerah, HIGH);
    buzzerInterval = 1000;

    if (currentTime - previousBuzzerTime >= buzzerInterval) {
      bunyiBuzzer(3);
      previousBuzzerTime = currentTime;
    }
  }
}

void sendToBlynk() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi Disconnected, skip kirim ke Blynk");
    return;
  }

  unsigned long currentTime = millis();
  if (currentTime - lastBlynkSend < delay_kirimKeBlynk) return;

  String statusServo  = isServoOpen ? "Terbuka" : "Tertutup";
  int btnServoState   = isServoOpen ? 1 : 0; 
  
  int sHijau  = digitalRead(ledHijau)     ? 255 : 0;
  int sKuning = digitalRead(ledKuning)    ? 255 : 0;
  int sMerah  = digitalRead(ledMerah)     ? 255 : 0;

  String url = String("https://blynk.cloud/external/api/batch/update?token=") + BLYNK_AUTH_TOKEN +
               "&V0=" + String(lastJarak1) +    
               "&V1=" + String(lastJarak2) +    
               "&V2=" + String(lastVolPersen) + 
               "&V3=" + statusServo +           
               "&V4=" + String(sHijau) +        
               "&V5=" + String(sKuning) +       
               "&V6=" + String(sMerah) +
               "&V8=" + String(btnServoState); 
  
  HTTPClient http;
  http.begin(url);
  
  int httpCode = http.GET();
  
  if (httpCode > 0) {
    Serial.println("Blynk HTTP Sent Code: " + String(httpCode));
  } else {
    Serial.println("Blynk HTTP Fail: " + http.errorToString(httpCode));
  }
  
  http.end();
  lastBlynkSend = currentTime;
}

void sendToSupabase() {
  if (WiFi.status() != WL_CONNECTED) return; 

  HTTPClient http;
  http.begin(SUPABASE_URL);
  http.addHeader("apikey", SUPABASE_KEY);
  http.addHeader("Authorization", "Bearer " + SUPABASE_KEY);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Prefer", "return=minimal");

  String payload = "{";
  payload += "\"jarak1\": "       + String(lastJarak1)    + ",";
  payload += "\"jarak2\": "       + String(lastJarak2)    + ",";
  payload += "\"volume\": "       + String(lastVolPersen) + ",";
  payload += "\"servo_state\": "  + String(isServoOpen ? "true" : "false") + ",";
  payload += "\"nama\": \""       + DEVICE_NAME           + "\"";
  payload += "}";

  http.setTimeout(3000); 
  int httpResponseCode = http.POST(payload);
  
  if (httpResponseCode > 0) Serial.println("Supabase Sent: " + String(httpResponseCode));
  else Serial.println("Supabase Error: " + String(httpResponseCode));
  
  http.end();
}

void bunyiBuzzer(int jumlah) {
  for (int i = 0; i < jumlah; i++) {
    digitalWrite(buzzerPin, HIGH);
    delay(100);
    digitalWrite(buzzerPin, LOW);
    delay(100);
  }
}

void checkNotifications() {
  unsigned long currentMillis = millis();

  if (volPersen >= 80 && volPersen < 90) {
    
    if (!isTimer80Running) {
      startTimer80      = currentMillis;
      isTimer80Running  = true;
    } 
    else if (currentMillis - startTimer80 >= detikNotif) {
      if (!notif80Sent) {
        Blynk.logEvent("warning_sampah", "Peringatan: Sampah_1 mencapai 80%.");
        notif80Sent = true; 
      }
    }
    
  } else {
    isTimer80Running = false;
    
    if (volPersen < 75) {
      notif80Sent = false;
    }
  }


  if (volPersen >= 90) {
    

    if (!isTimer90Running) {
      startTimer90      = currentMillis;
      isTimer90Running  = true;
    } 

    else if (currentMillis - startTimer90 >= detikNotif) {
      if (!notif90Sent) {
        Blynk.logEvent("warning_sampah", "BAHAYA: Sampah_1 Kritis 90% (Stabil). Segera buang!");
        notif90Sent = true;
      }
    }

  } else {
    isTimer90Running = false;

    if (volPersen < 85) {
      notif90Sent = false;
    }
  }
}


BLYNK_WRITE(VPIN_MODE_MANUAL) {
  manualMode = (param.asInt() == 1);
}

BLYNK_WRITE(VPIN_MANUAL_SERVO) {
  if (manualMode) {
    int val = param.asInt();
    if (val == 1) {
      myservo1.write(180);
      isServoOpen = true;
    } else {
      myservo1.write(0);
      isServoOpen = false;
    }
  } else {
    
  }
}

BLYNK_WRITE(VPIN_MANUAL_BUZZER) {
  if (param.asInt() == 1) {
    digitalWrite(buzzerPin, HIGH);
    delay(200);
    digitalWrite(buzzerPin, LOW);
  }
}
