#include <stdio.h> 

boolean activated = false;

//define 
//15 and 17 refers to A1 and A3 respectively
int stepPin[] = {4,6,8,10,12,15,17};
//14 and 16 refers to A0 and A2 respectively
int dirPin[] = {3,5,7,9,11,14,16};
int motorMapping[] = {4,6,0,5,1,3,2};
int enablePin = 2, ledPin = 13, potPin = 5, amountOfSteppers = 7;
boolean stepState[] = {false,false,false,false,false,false,false};
boolean dir[] = {false,false,false,false,false,false,false};
boolean moving[] = {false,false,false,false,false,false,false};
boolean previousDir[] = {true,true,true,true,true,true,true};

#define DOWN false
#define UP true

int state[] = {0,0,0,0,0,0,0};
int steps = 100;
char printMsg[33];
unsigned long lastFeedback = millis();
int feedbackTime = 1500;
unsigned long lastStep = micros();
int stepTime = 700;
unsigned long lastMsg = millis();

int maxWaitTime = 10000;
boolean idle = true;


long totalStepCount[] = {0,0,0,0,0,0,0};
long maxStepCount[] = {184714, 100289, 102129, 100000, 85214, 60645, 61711};
int safety = 5000;
int minStepCount[] = {0,0,0,0,0,0,0};
int currentMotor;

boolean override = false, goingHome = false;

void setup()
{
  pinMode(enablePin,OUTPUT);
  digitalWrite(enablePin,HIGH);
  
  for (int i=0; i<amountOfSteppers; i++) {
    pinMode(stepPin[i],OUTPUT);
    pinMode(dirPin[i],OUTPUT);
  }
  
  pinMode(ledPin,OUTPUT);
  
  //enable switch
  pinMode(A4,INPUT);
  //internal pullup
  digitalWrite(A4,HIGH);

  Serial.begin(115200);
}

void loop()
{  
  
  activated = digitalRead(A4); 
  
  if (Serial.available()) {
    //incoming
    byte a = Serial.read();
    
    // gimme ascii value back
    //    
    // if (a != 10) {
    //   Serial.print("got: ");
    //   Serial.println(int(a));
    // }
    
    if (a == 111 || a == 79) {
      //'o' / 'o' from processing = toggle override
      if (override) {
        Serial.println("override OFF");
        override = false;
      } else if (!override) {
        Serial.println("override ON");
        override = true;
      }
    }
    
    if (a == 117 || a == 85) {
      //'u' / 'u' from processing all up
      Serial.println("going up");
      for (int i = 0; i<amountOfSteppers; i++) {
        moving[i] = true;
        state[i] = 2;
        dir[i] = UP;
      }
      printMotorState();
    }
    
    if (a == 104 || a == 72) {
      //'h' / 'h' from processing = go home
      Serial.println("going home");
      goingHome = true;
      for (int i = 0; i<amountOfSteppers; i++) {
        moving[i] = true;
        state[i] = 2;
        dir[i] = UP;
      }
      printMotorState();
    }
    
    if (a == 115 || a == 32 || a == 83) {
      //'s' / ' ' / 's' from processing = all stop
      Serial.println("stop & override OFF");
      for (int i = 0; i<amountOfSteppers; i++) {
        moving[i] = false;
        state[i] = 0;
      }
      
      override = false;
      
      printMotorState();
    }
    
    if (a == 100 || a == 68) {
      //'d' / 'd' from processing = all down
      Serial.println("going down");
      for (int i = 0; i<amountOfSteppers; i++) {
        moving[i] = true;
        state[i] = 1;
        dir[i] = DOWN;
      }
      printMotorState();
    }
    
    
    if (a == 114 || a == 82) {
      //'r' / 'r' from processing = reset all motor count
      Serial.println("reset step count for all motors & override OFF");
      for (int i = 0; i<amountOfSteppers; i++) {
        totalStepCount[i] = 0;
        override = false;
      }
      printMotorState();
    }
    
    if (a == 99 || a == 67) {
      //'c' / 'c' from processing count/check
      printMotorState();
    }
    

    
    if (a >= 49 && a <= 55) {
      
      currentMotor = a-49;
      
      state[currentMotor] = state[currentMotor]++;
      if (state[currentMotor] == 3) state[currentMotor] = 0;
      
      override = true;
      
      Serial.print(currentMotor+1);
      Serial.print(" new state ");
      Serial.print(state[currentMotor]);
      
      if (state[currentMotor] == 0) {
        moving[currentMotor] = false;
        Serial.print(" [stop]");
      } else if (state[currentMotor] == 1) {
        moving[currentMotor] = true;
        dir[currentMotor] = DOWN;
        Serial.print(" [down]");
      } else if (state[currentMotor] == 2) {
        moving[currentMotor] = true;
        dir[currentMotor] = UP;
        Serial.print(" [up]");
      }
      Serial.println(" NB: override ON");
      printMotorState();
      
    }
  }
  
  //check if motors is out of bounds
  if (!override) {
    for (int i = 0; i<amountOfSteppers; i++) {
      if (totalStepCount[i] < minStepCount[i] && dir[i] == UP) {
        if (goingHome && moving[i]) {
          moving[i] = false;
          Serial.print(i);
          Serial.println(" arrived home");
          printMotorState();
        } else {
          dir[i] = DOWN;
          Serial.print("turning motor ");
          Serial.print(i);
          Serial.println(" [down]");
          printMotorState();
        }
      }
      if (totalStepCount[i] > maxStepCount[i]-safety && dir[i] == DOWN) {
          dir[i] = UP;
          Serial.print("turning motor ");
          Serial.print(i);
          Serial.println(" [up]");
          printMotorState();
        
      }
    }
    //check if all motors are home
    if (goingHome) {
      boolean allHome = true;
      for (int j = 0; j<amountOfSteppers; j++) {
        if (totalStepCount[j] > minStepCount[j]) allHome = false;
      }
      if (allHome) {
        goingHome = false;
        Serial.println("all home");
        for (int i = 0;i<amountOfSteppers; i++) {
          moving[i] = false;
        }
        printMotorState();
      }
    }
  }
  
  digitalWrite(enablePin,activated);
  digitalWrite(ledPin,!activated);
  
  for (int i = 0;i<amountOfSteppers; i++) {
    if (dir[i] != previousDir[i]) {
      digitalWrite(dirPin[motorMapping[i]],dir[i]);
      previousDir[i] = dir[i];
    }
    if (moving[i]) {
      stepState[i] = !stepState[i];
      digitalWrite(stepPin[motorMapping[i]],stepState[i]);
      if (dir[i] == DOWN) totalStepCount[i]++;
      if (dir[i] == UP) totalStepCount[i]--;
    }
  }
  
  delayMicroseconds(798);
  feedback();
}

void applyBitmask (byte a, byte b) {
  //direction
  dir[0] = HIGH&&(a&B00000001);
  dir[1] = HIGH&&(a&B00000010);
  dir[2] = HIGH&&(a&B00000100);
  dir[3] = HIGH&&(a&B00001000);
  dir[4] = HIGH&&(a&B00010000);
  dir[5] = HIGH&&(a&B00100000);
  dir[6] = HIGH&&(a&B01000000);

  //is it moving?
  moving[0] = HIGH&&(b&B00000001);
  moving[1] = HIGH&&(b&B00000010);
  moving[2] = HIGH&&(b&B00000100);
  moving[3] = HIGH&&(b&B00001000);
  moving[4] = HIGH&&(b&B00010000);
  moving[5] = HIGH&&(b&B00100000);
  moving[6] = HIGH&&(b&B01000000);
}

void printMotorState() {
  for (int i = 0;i<7;i++) {
    if (moving[i]) {
      if (dir[i] == UP) Serial.print('U');
      if (dir[i] == DOWN) Serial.print('D');
    } else {
      Serial.print('.');
    }
  }

  for (int i = 0; i<amountOfSteppers; i++) {
    Serial.print("\tc:");
    Serial.print(totalStepCount[i]);
  }
  Serial.println();

}

void feedback() {
  if (lastFeedback + feedbackTime < millis()) {
    
    lastFeedback = millis();
    
    // for (int i = 0;i<32;i++) {
    //   Serial.print(printMsg[i]);
    // }
    
    // Serial.println();
    // printMotorState();
    // Serial.print("motor debug: ");
    // Serial.print(currentMotor);
    // Serial.print("\ttotal steps: ");
    // Serial.println(totalStepCount[currentMotor]);
  }
}
