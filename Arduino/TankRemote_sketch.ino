#include <SPI.h>
#include <ble.h>
#include <Servo.h>

#define MOTOR_A_FORWARD 12
#define MOTOR_A_BREAK 40
#define MOTOR_A_POWER 3
#define MOTOR_B_FORWARD 13
#define MOTOR_B_BREAK 41
#define MOTOR_B_POWER 11
#define SERVO_HORIZONTAL 6
#define SERVO_VERTICAL 5

Servo servoHorizontal;
Servo servoVertical;

void setup() {
  SPI.setDataMode(SPI_MODE0);
  SPI.setBitOrder(LSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV16);
  SPI.begin();

  ble_begin();
  
  pinMode(MOTOR_A_FORWARD, OUTPUT); //Initiates Motor Channel A pin
  pinMode(MOTOR_A_BREAK, OUTPUT);  //Initiates Brake Channel A pin
  pinMode(MOTOR_A_POWER, OUTPUT);  //Initiates Power Channel A pin
  pinMode(MOTOR_B_FORWARD, OUTPUT); //Initiates Motor Channel B pin
  pinMode(MOTOR_B_BREAK, OUTPUT);  //Initiates Brake Channel B pin
  pinMode(MOTOR_B_POWER, OUTPUT);  //Initiates Power Channel B pin
  
  digitalWrite(MOTOR_A_BREAK, LOW);   //Disengage the Brake for Channel A
  digitalWrite(MOTOR_B_BREAK, LOW);   //Disengage the Brake for Channel B
  
  servoHorizontal.attach(SERVO_HORIZONTAL);
  servoVertical.attach(SERVO_VERTICAL);
}

void loop() {
  while (ble_available()) {
    // read out command and data
    byte data0 = ble_read();
    byte data1 = ble_read();
    byte data2 = ble_read();
    
    if (data0 == 0x01) { // Motor A direction
      if (data1 == 0x01) {
        digitalWrite(MOTOR_A_FORWARD, HIGH);
      } else {
        digitalWrite(MOTOR_A_FORWARD, LOW);
      }
    } else if (data0 == 0x02) { // Motor A speed
      analogWrite(MOTOR_A_POWER, data1);
    } else if (data0 == 0x03) { // Motor B direction
      if (data1 == 0x01) {
        digitalWrite(MOTOR_B_FORWARD, HIGH);
      } else {
        digitalWrite(MOTOR_B_FORWARD, LOW);
      }
    } else if (data0 == 0x04) { // Motor B speed
      analogWrite(MOTOR_B_POWER, data1);
    } else if (data0 == 0x05) {
      servoHorizontal.write(data1);
      servoVertical.write(data2);
    }
  }
  
  if (!ble_connected()) {
      analogWrite(MOTOR_A_POWER, 0);
      analogWrite(MOTOR_B_POWER, 0);
  }
  
  // Allow BLE Shield to send/receive data
  ble_do_events();  
}

