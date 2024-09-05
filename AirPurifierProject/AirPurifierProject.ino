#include "FirebaseESP8266.h"
#include <U8g2lib.h>
#include <ESP8266WiFi.h>
#include <Wire.h>
 
#define FIREBASE_HOST "____" 
#define FIREBASE_AUTH "____"
#define WIFI_SSID "____" // 연결 가능한 wifi의 ssid
#define WIFI_PASSWORD "____" // wifi 비밀번호

int driveState = 0; //Auto(0), Manual(1)
int AirState = 1; // Current air quality: Good(1), Normal(2), Bad(3), Worst(4)

typedef struct{
  int ENA;
  int IN1;
  int IN2;
} L298N;

typedef struct{
  int SIG;
  unsigned long duration=0, start_time=0, ms=10000, low_pulse=0;
  float ratio, concentration, value;
  void getPPD42N(){
    duration=pulseIn(SIG, LOW);  //low_pulse 변수에 10번핀이 LOW된 시간을 모두 더함
    low_pulse += duration;
    if(start_time+ms < millis()){  //10초에 한번씩 측정
      start_time=millis();  //측정시간 초기화
      ratio=low_pulse/(ms*10.0);  //계산공식
      concentration=1.1*pow(ratio,3)-3.8*pow(ratio,2)+520*ratio+0.62;
      value=concentration*100/13000;
      low_pulse=0;  //low_pulse 변수 초기화
    }
  }
  void getAirState(){
    if (value <= 15.0) AirState=1;
    else if (value <= 35.0) AirState=2;
    else if (value <= 75.0) AirState=3;
    else AirState=4;
  }
} PPD42N;

L298N my_l298n;
PPD42N my_ppd42n;
//U8GLIB_SH1106_128X64 u8g(U8G_I2C_OPT_NONE); //OLED 설정
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0);  // OLED 설정 <- 이걸로 해야 매 두 줄이 깨지지 않음
//U8G2_SSD1306_128X64_ALT0_F_HW_I2C u8g2(U8G2_R0, /* reset=*/ U8X8_PIN_NONE);   // same as the NONAME variant, but may solve the "every 2nd line skipped" problem

FirebaseData firebaseData;
FirebaseConfig config;
FirebaseAuth auth;

bool isConnected = true; //와이파이에 연결되어있는가?

//파이어베이스에서 읽거나 쓸 데이터들
bool Data_Auto = false;
int Data_FanSpeed = 0;
unsigned long long Data_FilterUsageDuration = 0;
int Data_FineDustCondition = 0;

//값을 특정 횟수 이상 읽어오지 못하면 연결이 끊긴 것으로 판단
unsigned long Offset = 700;
unsigned long Auto_start_time = 0;
unsigned long FanSpeed_start_time = 0;
unsigned long FilterUsageDuration_start_time = 0;
int Failed_Auto_Cnt = 0;
int Failed_FanSpeed_Cnt = 0;

//1시간 카운트
unsigned long timeCount = 0;

void setup(){
  Serial.begin(9600);
  my_l298n.ENA=D6;
  my_ppd42n.SIG=D5;
  u8g2.begin();
  pinMode(my_l298n.ENA, OUTPUT);
  pinMode(my_ppd42n.SIG, INPUT);
  my_ppd42n.start_time = millis();
  timeCount = millis();
  delay(1000);

  //20초 경과시 와이파이 연결을 포기함
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  int isTimeOut = 0;
  while(WiFi.status() != WL_CONNECTED){
    Serial.print(".");
    isTimeOut++; delay(500);
    if(isTimeOut>=40){isConnected = false; break;}
  }

  //와이파이에 연결되었을 시에만 파이어베이스에 연결
  if(isConnected==true){ 
    Serial.println(); Serial.print("Connected with IP: ");
    Serial.println(WiFi.localIP()); Serial.println();
    config.host = FIREBASE_HOST;
    config.signer.tokens.legacy_token = FIREBASE_AUTH;
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
    firebaseData.setBSSLBufferSize(1024, 1024);
    firebaseData.setResponseSize(1024);
    Firebase.setReadTimeout(firebaseData, 1000 * 60);
    Firebase.setwriteSizeLimit(firebaseData, "tiny");

    if(Firebase.ready()) Serial.println("ready");
    else isConnected = false;
  }
  if(isConnected==false){
    Serial.println();
    Serial.println("Can't Connect WiFi");
    Serial.println("If you want to use the App to control, reboot the AirPurifier.");
    Serial.println("The AirPurifier will be operated with Only Auto Mode");
    Serial.println();
  }
}

void loop(){
  
  //파이어베이스에 연결된 상태에만 읽기 시작
  if(isConnected){
    //Auto 읽어오기
    if(Auto_start_time+Offset < millis() && Firebase.getBool(firebaseData, "Auto")){
      Data_Auto = firebaseData.boolData(); Failed_Auto_Cnt=0;
      Auto_start_time = millis();
    } else Failed_Auto_Cnt++;

    //FanSpeed 읽어오기
    if(FanSpeed_start_time+Offset < millis() && Firebase.getInt(firebaseData, "FanSpeed")){
      Data_FanSpeed = firebaseData.intData(); Failed_FanSpeed_Cnt=0;
      FanSpeed_start_time = millis();
    } else Failed_FanSpeed_Cnt++;

    //현재 사용 기간 읽어오기 (시간 단위로 가져옴)
    if(FilterUsageDuration_start_time+Offset < millis() && Firebase.getInt(firebaseData, "FilterUsingDuration")){
      Data_FilterUsageDuration = firebaseData.intData();
      FilterUsageDuration_start_time = millis();
    }
  }

  //일정 횟수 이상 데이터를 읽어오지 못하면 연결 상태가 끊겼다고 판단
  if(Failed_Auto_Cnt>=10 || Failed_FanSpeed_Cnt>=10) isConnected = false;

  my_ppd42n.getPPD42N(); //미세먼지 측정 후 ppd42n.value에 저장
  my_ppd42n.getAirState(); //AirState에 현재 미세먼지 상태 저장 (1, 2, 3, 4)

  String tmp = "";
  tmp.concat(my_ppd42n.value);

  //디스플레이 시작
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_7x13B_tf);

  //미세먼지 농도 표시
  u8g2.drawStr(25,15,"PM25");
  u8g2.drawStr(65,15, tmp.c_str());

  //2024.09.05 : 이거를 clearbuffer 전에 넣으면 문제가 생기는 것 같음 (확실 X)
  //와이파이 연결을 안한 상태로 loop에 진입했을 때 문제가 있었는데 해결됨 
  //아마 이 코드가 원인이었을 것으로 추측하는데, 그냥 된 것일수도 있고, 확실하진 않음 
  if(!isConnected){ //연결이 되어있지 않다면 그 표시를 따로 해줘야됨
    Data_Auto = true;
    u8g2.drawStr(110, 15, "X");
  }
  
  //공기 질에 따라 상태 표시
  if(AirState==1) u8g2.drawStr(33, 37, "Good");
  if(AirState==2) u8g2.drawStr(30, 37, "Normal");
  if(AirState==3) u8g2.drawStr(35, 37, "Bad");
  if(AirState==4) u8g2.drawStr(30, 37, "Worst");

  
  if(Data_Auto==true){ //자동 모드 운전시
    if(AirState==1) {analogWrite(my_l298n.ENA, 100); u8g2.drawStr(70, 37, "(1)");}
    if(AirState==2) {analogWrite(my_l298n.ENA, 150); u8g2.drawStr(70, 37, "(2)");}
    if(AirState==3) {analogWrite(my_l298n.ENA, 200); u8g2.drawStr(70, 37, "(3)");}
    if(AirState==4) {analogWrite(my_l298n.ENA, 255); u8g2.drawStr(70, 37, "(4)");}
    u8g2.drawStr(25, 60, "(Auto Mode)");
  }

  else if(Data_Auto==false){ //수동 모드 운전시
    if(Data_FanSpeed==0) {analogWrite(my_l298n.ENA, 100); u8g2.drawStr(70, 37, "(1)");}
    if(Data_FanSpeed==1) {analogWrite(my_l298n.ENA, 150); u8g2.drawStr(70, 37, "(2)");}
    if(Data_FanSpeed==2) {analogWrite(my_l298n.ENA, 200); u8g2.drawStr(70, 37, "(3)");}
    if(Data_FanSpeed==3) {analogWrite(my_l298n.ENA, 255); u8g2.drawStr(70, 37, "(4)");}
    u8g2.drawStr(18, 60, "(Manual Mode)");
  }
  
  if(isConnected){
    //미세먼지 상태 전송
    Data_FineDustCondition = (int)(my_ppd42n.value); 
    Firebase.setInt(firebaseData, "FineDustCondition", Data_FineDustCondition);

    //1시간 지날때마다 카운트
    if(timeCount+3600000 < millis()){
      Firebase.setInt(firebaseData, "FilterUsingDuration", Data_FilterUsageDuration + 1);
      timeCount = millis();
    }
  }
  
  u8g2.sendBuffer();
}
