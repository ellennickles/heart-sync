

void serialEvent(Serial port) {
  try {
    String inData = port.readStringUntil('\n');
    inData = trim(inData);                      // cut off white space (carriage return)

    if (inData.charAt(0) == 'p') {                 // leading 'p' for pot readings
      if (inData.charAt(1) == 'a') {              //  leading 'a' for pot0 reading 
        String potReading = inData.substring(2); // remove the leading 'p' and 'a' and turn inData
        int potReadingInt = int(potReading);    // convert from string to int
        heartNew[0] = int(map(potReadingInt, 0, 1023, 0, 360)); // map to HSB color mode values
      }
      if (inData.charAt(1) == 'b') {            //  leading 'b' for pot1 reading 
        String potReading = inData.substring(2); // remove the leading 'a' and 'b' and turn inData
        int potReadingInt = int(potReading);       //convert from string to an int  
        heartNew[1] = int(map(potReadingInt, 0, 1023, 0, 360)); // map to HSB color mode values
      }
    } else if (inData.charAt(0) == 'x') {
      if (inData.charAt(1) == '0') {            // a pulse happened for sensorA0
        //println("x0");
        beat[0] = 20;                           // begin timer
      }
      if (inData.charAt(1) == '1') {            // a pulse happened for sensorA1
        //println("x1");
        beat[1] = 20;                            // begin timer
      }
    } else {

      for (int i=0; i<numSensors; i++) {
        if (inData.charAt(0) == 'a'+i) {           // leading 'a' for raw sensor data
          inData = inData.substring(1);           // cut off the leading 'a'
          Sensor[i] = int(inData);                // convert the string to usable int
        }
        if (inData.charAt(0) == 'A'+i) {           // leading 'A' for BPM data
          inData = inData.substring(1);           // cut off the leading 'A'
          BPM[i] = int(inData);                   // convert the string to usable int
          heartRate[i] = 100;                      // begin timer to compare BPM values
        }
        //if (inData.charAt(0) == 'M'+i) {          // leading 'M' means IBI data
        //  inData = inData.substring(1);           // cut off the leading 'M'
        //  IBI[i] = int(inData);                   // convert the string to usable int
        //}
      }
    }
  }
  catch(Exception e) {
    // print("Serial Error: ");
    // println(e.toString());
  }
}