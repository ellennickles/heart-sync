/*
Heart Sync by Ellen Nickles
 Final Project for Intro to Physical Computing and Intro to Computational Media
 ITP NYU Fall 2017
 
 Modification of an original sketch from Joel Murphy: 
 https://github.com/WorldFamousElectronics/PulseSensorAmped_2_Sensors
 
 Also includes a modified sketch from Daniel Shiffman:
 https://processing.org/examples/simpleparticlesystem.html
 */

/*
The MIT License (MIT)
 
 Copyright (c) 2016 Joel Murphy
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import processing.serial.*;
int numSensors = 2;  // number of pulse sensors

// variables and initializations to find the correct serial port
Serial port;
String serialPort;
String[] serialPorts = new String[Serial.list().length];
boolean serialPortFound = false;
Radio[] button = new Radio[Serial.list().length*2];
int numPorts = serialPorts.length;
boolean refreshPorts = false;

// variables for "heart" ellipses
float[] heartX;
float[] targetX;
int heartY;
float absoluteVal;
float lerpMotion;
float[] radius; 
float[] targetRadius;
float lerpRadius;
float newRadius;
float startWeight;
float targetWeight;
int[] heartColor;
int[] heartNew;

// variables for raw sensor data, beat detection, and BPMs
int[] Sensor;        // holds pulse sensor data from Arduino
int[] BPM;           // holds heart rate value from Arduino
int[][] RawPPG;      // holds heartbeat wavefrom data before scaling
int[][] ScaledPPG;   // used to position scaled heartbeat waveform
float offset;        // used when scaling pulse waveform (to old pulse window)
int beat[];          // timer for the heart 'pulse'
int heartRate[];     // timer to compare BPM values

PFont font;          
int margin;   

ParticleSystem ps;


void setup() {

  // initialize environment
  fullScreen(); 
  frameRate(100);
  colorMode(HSB, 360, 100, 100);
  background(0, 0, 100);
  font = loadFont("Arial-BoldMT-24.vlw");
  textFont(font);
  textAlign(CENTER);
  ellipseMode(CENTER);
  margin = 20; 

  // initialize values for "heart" ellipses
  heartX = new float[numSensors];
  heartX[0] = width/4;   
  heartX[1] = width-width/4;
  targetX = new float[numSensors];    
  heartY = height/2;
  lerpMotion = 0.3;
  radius = new float[numSensors];
  radius[0] = radius[1] = 1;
  targetRadius = new float[numSensors];
  lerpRadius = 0.1;
  startWeight = 1;
  targetWeight = 75;
  heartColor = new int[numSensors];
  heartNew = new int[numSensors];

  // initialize values for raw sensor data, beat detection, and BPMs
  Sensor = new int[numSensors];      // holds pulse sensor data from Arduino
  BPM = new int[numSensors];         // holds heart rate value from Arduino
  RawPPG = new int[numSensors][width];   // initialize raw pulse waveform array
  ScaledPPG = new int[numSensors][width]; // initialize scaled pulse waveform array
  beat = new int[numSensors];             // timer for the heart 'pulse'
  heartRate = new int[numSensors];        // timer to compare BPM values

  // go find the Arduino
  fill(0, 0, 0);
  text("Select Serial Port", margin*6, margin*3);
  listAvailablePorts();

  resetDataTraces();    // set the pusle waveform visualizer lines to 0 

  ps = new ParticleSystem(new PVector(width/2, height/2));
}


void draw() {
  if (serialPortFound) {
    background(0, 0, 0);
    drawPulseWaveforms();  
    drawHearts();
    updateHeartColors(); 
    ps.run();
  } else { // scan to find the serial port
    autoScanPorts();

    if (refreshPorts) {
      refreshPorts = false;
      listAvailablePorts();
    }

    for (int i=0; i<numPorts+1; i++) {
      button[i].overRadio(mouseX, mouseY);
      button[i].displayRadio();
    }
  }
} 

void updateHeartColors() {
  for (int i=0; i<numSensors; i++) {
    heartColor[i]=heartNew[i];
  }
}


void drawPulseWaveforms() {
  //heartA0, left to right across screen
  int i = 0;
  RawPPG[i][width-1] = (1023 - Sensor[i]);   // place the new raw datapoint at the end of the array

  for (int j = 0; j < width-1; j++) {                  // move the pulse waveform by
    RawPPG[i][j] = RawPPG[i][j+1];                    // shifting all raw datapoints one pixel left
    float dummy = RawPPG[i][j] * 0.525/numSensors;   // adjust the raw data to the selected scale
    ScaledPPG[i][j] = int(dummy);
  }
  stroke(heartColor[i], 100, 100, 100);     // color for the pulse waveform
  strokeWeight(2);
  noFill();
  beginShape();                             
  for (int x = 1; x < width-1; x++) {
    vertex(x-2, ScaledPPG[i][width - x]);                    // draw a line connecting the data points
  }
  endShape();

  //heartA1, right to left across screen
  i = 1;
  RawPPG[i][width-1] = (1023 - Sensor[i]);   // place the new raw datapoint at the end of the array

  for (int j = 0; j < width-1; j++) {                  // move the pulse waveform by
    RawPPG[i][j] = RawPPG[i][j+1];                    // shifting all raw datapoints one pixel right
    float dummy = RawPPG[i][j] * 0.525/numSensors;   // adjust the raw data to the selected scale, 0.525 for MacBook
    offset = float(height-height/4); 
    ScaledPPG[i][j] = int(dummy) + int(offset);   // transfer the raw data array to the scaled array
  }
  stroke(heartColor[i], 100, 100, 100);                      // color for the pulse waveform
  strokeWeight(2);
  noFill();
  beginShape();                                 
  for (int x = 1; x < width-1; x++) {
    vertex(x+0, ScaledPPG[i][x]);    //draw a line connecting the data points
  }
  endShape();
}


void drawHearts() {    
  // draw ellipses for each sensor at Arduino analog pins, heartA0 and heartA1
  for (int i=0; i<numSensors; i++) {
    stroke(heartColor[i], 100, 100, 25); 
    fill(heartColor[i], 100, 100, 25);          
    beat[i]--;                       // beat is used to time how long the heart graphic swells when a heart beats
    beat[i] = max(beat[i], 0);       // don't let the beat variable go into negative numbers
    if (beat[i] > 0) {               // if a beat happened recently,
      strokeWeight(targetWeight);          // increase heart size
    }
    targetRadius[i] = map(Sensor[i], 0, 1023, 10, height);
    radius[i] = lerp(radius[i], targetRadius[i], lerpRadius);
    for (int j = 2; j <= 8; j+=2) {
      ellipse(heartX[i], heartY, radius[i]*0.10*j, radius[i]*0.10*j);
    }
    strokeWeight(startWeight);                // reset the strokeWeight for next time
  }

  // move ellipses according to mapped values of absolute value differences
  absoluteVal = abs(BPM[0]-BPM[1]);
  heartRate[0]--;
  heartRate[1]--;
  if ((heartRate[0] > 0) && (heartRate[1] > 0)) {
    targetX[0] = map(absoluteVal, 0, 150, (width/2), (width/4));
    targetX[1] = map(absoluteVal, 0, 150, (width/2), (width-width/4));
    heartX[0] = lerp(heartX[0], targetX[0], lerpMotion);
    heartX[1] = lerp(heartX[1], targetX[1], lerpMotion);

    // if the heart rates are close enough, then drawMore
    if (absoluteVal >= 0 && absoluteVal <= 3) {            
      drawMore();
    }
  }
  // return ellipses to starting points
  else {                        
    heartX[0] = lerp(heartX[0], width/4, lerpMotion);
    heartX[1] = lerp(heartX[1], width-width/4, lerpMotion);
  }
}


void drawMore() {
  for (int i=0; i<numSensors; i++) {        
    beat[i]-=2;                       // beat is used to time how long the particles are generated
    beat[i] = max(beat[i], 0);       // don't let the beat variable go into negative numbers
    if (beat[i] > 0) {               // if a beat happened recently,
      ps.addParticle();            // add particle
    }
  }
}


void resetDataTraces() {
  for (int i=0; i<numSensors; i++) {
    Sensor[i] = 512;
    for (int j=0; j<width; j++) {
      RawPPG[i][j] = 1024 - Sensor[i]; // initialize the pulse window data line to V/2
    }
  }
}


void listAvailablePorts() {
  println(Serial.list());    // print a list of available serial ports to the console
  serialPorts = Serial.list();
  fill(0, 0, 0);
  textFont(font, 16);
  textAlign(LEFT);
  // set a counter to list the ports backwards
  int yPos = 0;

  for (int i=numPorts-1; i>=0; i--) {
    button[i] = new Radio(35, 95+(yPos*20), 12, color(180), color(80), color(255), i, button);
    text(serialPorts[i], 50, 100+(yPos*20));
    yPos++;
  }
  int p = numPorts;
  fill(0, 0, 0);
  button[p] = new Radio(35, 95+(yPos*20), 12, color(180), color(80), color(255), p, button);
  text("Refresh Serial Ports List", 50, 100+(yPos*20));
  textFont(font);
  textAlign(CENTER);
}

void autoScanPorts() {
  if (Serial.list().length != numPorts) {
    if (Serial.list().length > numPorts) {
      println("New Ports Opened!");
      int diff = Serial.list().length - numPorts;  // was serialPorts.length
      serialPorts = expand(serialPorts, diff);
      numPorts = Serial.list().length;
    } else if (Serial.list().length < numPorts) {
      println("Some Ports Closed!");
      numPorts = Serial.list().length;
    }
    refreshPorts = true;
    return;
  }
}