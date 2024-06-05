#include "U8glib.h"

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

UltraS us1, us2, us3; //초음파 센서 설정

U8GLIB_SH1106_128X64 u8g(U8G_I2C_OPT_NONE); //OLED 설정

int getSurrDistState(){
  if (us1.getDist() <= 15.0 || us2.getDist() <= 15.0 || us3.getDist() <= 15.0) return 1;
  else return 0;
}

int state = 0; // Current air quality: Good(1), Normal(2), Bad(3), Worst(4)
int surrDistState = 0; // Distance to surroundings: Close(1), Adequate(0)

//PPD42N 미세먼지 센서용 변수
long duration, start_time, ms=20000, low_pulse;
float ratio, concentration, value;
int PPD42NSIG = 10; //미세먼지 센서 신호선 번호 설정

void setup() {
  us1.echo = 22; us1.trig = 23;
  us2.echo = 24; us2.trig = 25;
  us3.echo = 26; us3.trig = 27;

  Serial.begin(9600);
  u8g.setFont(u8g_font_7x13B);
  pinMode(us1.echo, INPUT); pinMode(us2.echo, INPUT); pinMode(us3.echo, INPUT);
  pinMode(us1.trig, OUTPUT); pinMode(us2.trig, OUTPUT); pinMode(us3.trig, OUTPUT);

  pinMode(PPD42NSIG, INPUT);  //청색선을 입력선으로 10번핀에 연결
  start_time=millis();  //시작된 시간을 측정

  delay(1000);
}

float getPPD42N(){
  duration=pulseIn(PPD42NSIG, LOW);  //low_pulse 변수에 10번핀이 LOW된 시간을 모두 더함
  low_pulse += duration;
  if(start_time+ms < millis()){  //3초에 한번씩 측정
    start_time=millis();  //측정시간 초기화
    ratio=low_pulse/(ms*10.0);  //계산공식
    concentration=1.1*pow(ratio,3)-3.8*pow(ratio,2)+520*ratio+0.62;
    value=concentration*100/13000;
    low_pulse=0;  //low_pulse 변수 초기화
  }
}

void loop() {
  surrDistState = getSurrDistState(); //거리 정보 갱신 (적절하면 0, 가까우면 1)
  getPPD42N(); //PPD42N 출력값 갱신
  u8g.firstPage();
  do {
    String tmp = "";
    tmp.concat(value);
    u8g.drawStr(20,10,tmp.c_str());

    if (value <= 15.0) u8g.drawStr(20, 50, "Good");
    else if (value <= 35.0) u8g.drawStr(20, 50, "Normal");
    else if (value <= 75.0) u8g.drawStr(20, 50, "Bad");
    else u8g.drawStr(20, 50, "Worst");
  } while (u8g.nextPage());
}


//결선 확인

/*
초음파 1 (Echo 22, Trig 23)
초음파 2 (Echo 24, Trig 25)
초음파 3 (Echo 26, Trig 27)
Vcc 5V, Gnd Gnd

PPD42NS
1 GND
3 Vcc
4 Sig (아두이노 10에 연결)

OLED Display
SDA
SCL
Vcc
Gnd
RES
*/
