#include "U8glib.h"

int AirState = 1; // Current air quality: Good(1), Normal(2), Bad(3), Worst(4)
int surrDistState = 0; // Distance to surroundings: Close(1), Adequate(0)

typedef struct{
  int echo;
  int trig;
  float getDist(){
    float ret;
    float cycletime;
    digitalWrite(trig, HIGH);
    delayMicroseconds(10);
    digitalWrite(trig, LOW);
    cycletime = pulseIn(echo, HIGH);
    ret = (cycletime * 0.0343) / 2;  // speed of sound is 0.0343 cm/us
    return ret;
  }
} UltraS;

typedef struct{
  int ENA;
  int IN1;
  int IN2;
} L298N;

typedef struct{
  int SIG;
  long duration, start_time, ms=20000, low_pulse;
  float ratio, concentration, value;

  float getPPD42N(){
    duration=pulseIn(SIG, LOW);  //low_pulse 변수에 10번핀이 LOW된 시간을 모두 더함
    low_pulse += duration;
    if(start_time+ms < millis()){  //3초에 한번씩 측정
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

UltraS my_us1, my_us2, my_us3;
L298N my_l298n;
PPD42N my_ppd42n;

U8GLIB_SH1106_128X64 u8g(U8G_I2C_OPT_NONE); //OLED 설정

void getSurrDistState(){
    if (my_us1.getDist() <= 15.0 || my_us2.getDist() <= 15.0 || my_us3.getDist() <= 15.0) surrDistState = 1;
    else surrDistState = 0;
}

void setup() {
  my_us1.echo = 22; my_us1.trig = 23;
  my_us2.echo = 24; my_us2.trig = 25;
  my_us3.echo = 26; my_us3.trig = 27;

  my_l298n.ENA = 7;
  my_l298n.IN1 = 6;
  my_l298n.IN2 = 5;

  my_ppd42n.SIG = 10;

  Serial.begin(9600);
  u8g.setFont(u8g_font_7x13B);

  pinMode(my_us1.echo, INPUT); pinMode(my_us2.echo, INPUT); pinMode(my_us3.echo, INPUT);
  pinMode(my_us1.trig, OUTPUT); pinMode(my_us2.trig, OUTPUT); pinMode(my_us3.trig, OUTPUT);

  pinMode(my_l298n.ENA, OUTPUT); pinMode(my_l298n.IN1, OUTPUT); pinMode(my_l298n.IN2, OUTPUT);

  pinMode(my_ppd42n.SIG, INPUT);  //청색선을 입력선으로 10번핀에 연결
  my_ppd42n.start_time = millis();  //시작된 시간을 측정

  delay(1000);
}

void loop() {
  digitalWrite(my_l298n.IN1, LOW); digitalWrite(my_l298n.IN2, HIGH);

  getSurrDistState();
  my_ppd42n.getPPD42N();
  my_ppd42n.getAirState();

  if(AirState==1) analogWrite(my_l298n.ENA, 100);
  if(AirState==2) analogWrite(my_l298n.ENA, 150);
  if(AirState==3) analogWrite(my_l298n.ENA, 200);
  if(AirState==4) analogWrite(my_l298n.ENA, 255);

  u8g.firstPage();
  do {
    String tmp = "";
    tmp.concat(my_ppd42n.value);
    u8g.drawStr(20,10,tmp.c_str());

    if(AirState==1) u8g.drawStr(20, 50, "Good");
    if(AirState==2) u8g.drawStr(20, 50, "Normal");
    if(AirState==3) u8g.drawStr(20, 50, "Bad");
    if(AirState==4) u8g.drawStr(20, 50, "Worst");
  } while (u8g.nextPage());
}
