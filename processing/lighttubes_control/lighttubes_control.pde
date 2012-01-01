// light prolapse
// this processing sketch used only as serial interface to code running on the arduino

import processing.serial.*;

Serial serial;
String SERIAL_PORT="/dev/tty.usbserial-ym1-100";
boolean doSerial = false;

PFont font;
String[] instructions;

int textX = 10;

color selected = #A9AD0C, hover = #FF17FC;

void setup() {
  size(700, 350, JAVA2D);
  smooth();

  font = loadFont("DIN-Light-24.vlw");
  textFont(font,24);
  
  instructions = loadStrings("instructions.txt");

  String [] serialPorts = Serial.list();
  for (int i = 0; i<serialPorts.length; i++) {
    println("serial port: "+i+"\t"+serialPorts[i]);
    if (serialPorts[i].equals(SERIAL_PORT)) doSerial = true;
  }
  
  if (doSerial) {
    serial = new Serial(this, SERIAL_PORT, 115200);
  }
}

void draw() {
  background(0);
  for (int i = 0; i<instructions.length; i++) {
    text(instructions[i],10,25+i*24);
  }
}

void serialEvent(Serial serial) {
  int inByte = serial.read();
  print (char(inByte));
}

void keyPressed() {
  serial.write(char(keyCode));
}




