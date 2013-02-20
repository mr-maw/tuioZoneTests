/*
Brightness & Contrast

This demo uses TUIO-based rotation gesture to increase 
and decrease brightness or contrast on an image. 
The mode can be set by touching on one of the purple tool 
selection zones.  
*/

import oscP5.*;
import netP5.*;
import tuioZones.*;

TUIOzoneCollection zones;

PImage img;
PImage output;
float tintValue;
float oldRot;
color histColor;
String name;

// Image properties
int imageWidth = 640;
int imageHeight = 573;
int imageOffsetX = 120;
int imageOffsetY = 0;

// Tool zone params
String[] toolZones = {"brightness", "contrast", "undecided", "reset"};
int toolZoneHeight = 100;
int toolZoneWidth = toolZoneHeight;
int offsetX = 10;
int offsetY = 60;
int zoneMargin = 40;
int zoneStrokeOffset = 10;
String currentlyPressedZone = null;

boolean adjustmentZoneActive = false;
String adjustmentZone = "gesture";
String imageFilename = "butterfly.jpg";

void setup() {
  size(760,573);
  tintValue = 255;
  
  zones=new TUIOzoneCollection(this);
  zones.setZone("image", imageOffsetX,0,imageWidth,imageHeight);
  zones.setZoneParameter("image","SCALABLE",true);
  zones.setZoneParameter("image","DRAGGABLE",true);
  img = loadImage(imageFilename);
  output = img;
  
  createToolZones(toolZones);
  
  noFill();
  smooth();
  
  histColor = color(255,0,255, 160);
  name = "brightness";
}

void mouseClicked(){
  reset();
}

/* Return the image to its original state */
void reset(){
  println("Resetting.");
  img = loadImage(imageFilename);
  output = img;
  img.updatePixels();
  output.updatePixels();
  output.updatePixels();
}

void draw(){
  background(0);
  noFill();

  // use the zone coordinates and size to display the image
  image(
    output, 
    zones.getZoneX("image"),
    zones.getZoneY("image"),
    zones.getZoneWidth("image"),
    zones.getZoneHeight("image")
  );
  
  if (isToolZonePressed()) {
    activateAdjustmentIfNotActive();
    renderCurrentlyPressedZone();
    applyToolToImage();
  } else {
    deactivateAdjustment();
    renderAllToolZones();
  }
  
  noStroke();
  fill(255);
  rect(0, 0, 94, 22);
  fill(0);
  text(name, 10, 15);
}

/*
  Tool selection methods
*/

boolean isToolZonePressed() {
  return getCurrentlyPressedZone() != null;
}

boolean activateAdjustmentIfNotActive() {
  if (adjustmentZoneActive) {
    return false;
  }
  zones.setZone(
    adjustmentZone, 
    100,0, 
    width-100,height
    );
  adjustmentZoneActive = true;
  return true;
}

void deactivateAdjustment() {
  zones.killZone(adjustmentZone);
  adjustmentZoneActive = false;
}

void renderCurrentlyPressedZone() {
  fill(100,0,100);
  stroke(200,200,0);
  strokeWeight(4);
  zones.drawRect(getCurrentlyPressedZone());
  noFill();
  noStroke();
}

String getCurrentlyPressedZone() {
  // This first check for increased performance with many zones.
  if (currentlyPressedZone != null && zones.isZonePressed(currentlyPressedZone)) {
    return currentlyPressedZone;
  }
  for (String zone : toolZones) {
    if (zones.isZonePressed(zone)) {
      currentlyPressedZone = zone;
      return zone;
    }
  }
  return null;
}

void renderAllToolZones() {
  fill(100,0,100);
  noStroke();
  for (String zone : toolZones) {
    zones.drawRect(zone);
  }
  noFill();
}

void applyToolToImage() {
  if (getCurrentlyPressedZone() == "reset") {
    reset();
    return;
  }
  
  name = getCurrentlyPressedZone();
  // show the histogram overlay
  drawHistogram(output, histColor);
  
  rect(
    zones.getZoneX("image"),zones.getZoneY("image"),
    zones.getZoneWidth("image"),zones.getZoneHeight("image")
  );
  
  float rot = zones.getGestureRotation("gesture");
  
  // Alright, let's do something!
  if (rot != oldRot) {
    float delta = rot-oldRot;
    /* Ignore huge jumps..
    These happen in 2 cases in particular:
    1) when the second touch point moves straight above the first
    2) when the touch has been released and rotation starts again 
      (as the old rotation was something completely different)
    */
    if (abs(delta) > .5) delta = 0;
    //println(delta);
    if (name == "brightness") brightness(img, output, delta);
    else if (name == "contrast") contrast(img, output, delta);
  }
  oldRot = rot;
}

/*
  Image adjustment methods
*/

void drawHistogram (PImage img, color histColor) {
  int[] hist = new int[256];
  
  int histogramX = imageOffsetX;
  int histogramY = 0;
  int histogramWidth = imageWidth;
  int histogramHeight = imageHeight;
  
  img.loadPixels();
  
  // Calculate the histogram
  for (int i = 0; i < imageWidth; i++) {
    for (int j = 0; j < imageHeight; j++) {
      int bright = int(brightness(img.pixels[j*imageWidth+i]));
      hist[bright]++; 
    }
  }
  
  // Find the largest value in the histogram
  int histMax = max(hist);
  
  strokeWeight(1);
  stroke(histColor);
  for (int i = 0; i < histogramWidth; i++) {
    // Map i (from 0..img.width) to a location in the histogram (0..255)
    int which = int(map(i, 0, imageWidth, 0, 255));
    // Convert the histogram value to a location between 
    // the bottom and the top of the picture
    int y = int(map(hist[which], 0, histMax, histogramY + histogramHeight, histogramY));
    line(histogramX + i, histogramY + histogramHeight, histogramX + i, y);
  }
}



void contrast(PImage input, PImage output, float change) {
  //println(change);
  // amplification for the change
  float k = .2;
  
  for (int x = 0; x < input.width; x++) {
    for (int y = 0; y < input.height; y++ ) {
      // Calculate the 1D pixel location
      int i = x + y*input.width;
      // Get the R,G,B values from image
      //int r = (int) red(input.pixels[i]);
      //int g = (int) green(input.pixels[i]);
      //int b = (int) blue(input.pixels[i]);
       
      // Much faster RGB values (uses bit-shifting)
      int r = (input.pixels[i] >> 16) & 0xFF; //like calling the function red(), but faster
      int g = (input.pixels[i] >> 8) & 0xFF;
      int b = input.pixels[i] & 0xFF; 
      
      
      r *= 1 + change*k;
      g *= 1 + change*k;
      b *= 1 + change*k;
      //if (x == 0 && y == 0) println("rgb: "+r+", "+g+", "+b);
      
      // Constrain RGB to between 0-255
      //r = constrain(r,0,255);
      //g = constrain(g,0,255);
      //b = constrain(b,0,255);
      
      // faster
      r = r < 0 ? 0 : r > 255 ? 255 : r;
      g = g < 0 ? 0 : g > 255 ? 255 : g;
      b = b < 0 ? 0 : b > 255 ? 255 : b;
      
      
      // Make a new color and set pixel in the window
      
      //color c = color(r,g,b);
      //output.pixels[i] = c;
      
      // bitshift'd
      output.pixels[i]= 0xff000000 | (r << 16) | (g << 8) | b;
    }
  }
  input.updatePixels();
  output.updatePixels();
}

void brightness(PImage input, PImage output, float change) {
  //println(change);
  // amplification for the change
  float k = 20.0;
  
  for (int x = 0; x < input.width; x++) {
    for (int y = 0; y < input.height; y++ ) {
      // Calculate the 1D pixel location
      int i = x + y*input.width;
      // Get the R,G,B values from image
      //int r = (int) red(input.pixels[i]);
      //int g = (int) green(input.pixels[i]);
      //int b = (int) blue(input.pixels[i]);
       
      // Much faster RGB values (uses bit-shifting)
      int r = (input.pixels[i] >> 16) & 0xFF; //like calling the function red(), but faster
      int g = (input.pixels[i] >> 8) & 0xFF;
      int b = input.pixels[i] & 0xFF; 
      
      
      r = (int)(r + change*k);
      g = (int)(g + change*k);
      b = (int)(b + change*k);
      if (x == 0 && y == 0) println("rgb: "+r+", "+g+", "+b);
      
      // Constrain RGB to between 0-255
      //r = constrain(r,0,255);
      //g = constrain(g,0,255);
      //b = constrain(b,0,255);
      
      // faster
      r = r < 0 ? 0 : r > 255 ? 255 : r;
      g = g < 0 ? 0 : g > 255 ? 255 : g;
      b = b < 0 ? 0 : b > 255 ? 255 : b;
      
      
      // Make a new color and set pixel in the window
      
      //color c = color(r,g,b);
      //output.pixels[i] = c;
      
      // bitshift'd
      output.pixels[i]= 0xff000000 | (r << 16) | (g << 8) | b;
    }
  }
  input.updatePixels();
  output.updatePixels();
}

/*
  Misc. util methods
*/

void createToolZones(String[] zoneNames) {
  zones.setZone(
    toolZones[0], 
    offsetX,offsetY, 
    toolZoneWidth,toolZoneHeight
    );
  zones.setZone(
    toolZones[1], 
    offsetX,offsetY + toolZoneHeight + zoneMargin, 
    toolZoneWidth,toolZoneHeight
    );
  zones.setZone(
    toolZones[2], 
    offsetX,offsetY + toolZoneHeight*2 + zoneMargin*2, 
    toolZoneWidth,toolZoneHeight
    );
    
  zones.setZone(
    toolZones[3],
    offsetX, offsetY + toolZoneHeight*3 + zoneMargin*3,
    toolZoneWidth,toolZoneHeight/2
  );
}
