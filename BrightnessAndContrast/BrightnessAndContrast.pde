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

//blur kernel
float v2 = 1.0/9.0;
float[][] kernel = {
  {
    v2, v2, v2
  }
  , {
    v2, v2, v2
  }
  , {
    v2, v2, v2
  }
};

float brushScale;
// Icon props
PImage brightnessIcon;
PImage contrastIcon;
PImage blurIcon;
PImage resetIcon;
int iconWidth = 64;
int iconHeight = 64;

// Tool zone params
String[] toolZones = {"brightness", "contrast", "blur", "reset"};
int toolZoneHeight = 100;
int toolZoneWidth = toolZoneHeight;
int offsetX = 10;
int offsetY = 10;
int zoneMargin = 10;
int zoneStrokeOffset = 10;
String currentlyPressedZone = null;

boolean adjustmentZoneActive = false;
String adjustmentZone = "gesture";
String imageFilename = "butterfly.jpg";

void setup() {
  size(760,573);
  tintValue = 255;
  brushScale = 1.0;
  
  // Create tuioZones
  zones=new TUIOzoneCollection(this);
  zones.setZone("image", imageOffsetX,imageOffsetY,imageWidth,imageHeight);
  zones.setZoneParameter("image","SCALABLE",true);
  zones.setZoneParameter("image","DRAGGABLE",true);
  
  // Load the image and the "adjusted" image
  img = loadImage(imageFilename);
  output = img;
  
  // Icons
  brightnessIcon = loadImage("brightness.png");
  contrastIcon = loadImage("contrast.png");
  blurIcon = loadImage("smudge.png");
  resetIcon = loadImage("reset.png");
  
  createToolZones(toolZones);
  
  noFill();
  smooth();
  
  histColor = color(255,0,255);
  name = "brightness";
}

void mouseClicked(){
  reset();
}

/* Return the image to its original state */
void reset(){
  //println("Resetting.");
  zones.killZone("image");
  zones.setZone("image", imageOffsetX,imageOffsetY,imageWidth,imageHeight);
  zones.setZoneParameter("image","SCALABLE",true);
  zones.setZoneParameter("image","DRAGGABLE",true);
  img = loadImage(imageFilename);
  output = img;
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
  renderZone(getCurrentlyPressedZone());
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

void renderZone(String zone) {
  zones.drawRect(zone);
    
  PImage icon = null;
  if (zone == "brightness") icon = brightnessIcon;
  else if (zone == "contrast") icon = contrastIcon;
  else if (zone == "blur") icon = blurIcon;
  else if (zone == "reset") icon = resetIcon;
  
  if (icon != null) {
    image(
      icon,
      (int)(zones.getZoneX(zone) + zones.getZoneWidth(zone)/2.0 - iconWidth/2.0),
      (int)(zones.getZoneY(zone) + zones.getZoneHeight(zone)/2.0 - iconHeight/2.0),
      iconWidth,
      iconHeight
    );
  }
}

void renderAllToolZones() {
  fill(100,0,100);
  noStroke();
  for (String zone : toolZones) {
    renderZone(zone);
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
  
  int[] zData = zones.getZoneData("image");
  float scale = zones.getZoneScale("image");
  
  float rot = zones.getGestureRotation("gesture");
  

  float delta = 0;
  // Alright, let's do something!
  if (rot != oldRot) {
    delta = rot-oldRot;
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
  
  int[] cursor = new int[2];
  int[][] cursors = zones.getPoints();
  if(zones.isZonePressed("gesture")) {
  float bScale = zones.getGestureScale("gesture");
  println("scale: " + bScale);
  if(bScale >= 1.0) {
  brushScale += (bScale == 1.0 ? 0 : bScale/10);
  } else {
  brushScale -= bScale;  
  }
  cursor[0] = cursors[1][0];
  cursor[1] = cursors[1][1];
  drawCursor(cursor, max(1, brushScale)*scale);
  cursor = mapCursorToPixels(cursor, zData[0], zData[1], zData[2], zData[3], scale);
  }
  if (name == "blur" && cursor != null) {
      blur(img, output, cursor, 3 + round(brushScale));
  }
}

//Maps cursor coordinates to image pixels.
int[] mapCursorToPixels(int[] cursor, int imgX, int imgY, int imgW, int imgH, float imgScale) {
  float[] coords = new float[2];
  coords[0] = (cursor[0]-imgX)/imgScale;
  coords[1] = (cursor[1]-imgY)/imgScale;
  int[] cursorInImgCoords = new int[2];
  cursorInImgCoords[0] = round(constrain(coords[0], 0, imgW));
  cursorInImgCoords[1] = round(constrain(coords[1], 0, imgH));
  if (cursorInImgCoords[0] <= 0 || cursorInImgCoords[1] <= 0 ||
    cursorInImgCoords[0] >= imgW || cursorInImgCoords[1] >= imgH) {
    setToOutOfBounds(cursorInImgCoords);
  }
  return cursorInImgCoords;
}

void setToOutOfBounds(int[] coords) {
  coords[0] = -1;
  coords[1] = -1;
}

boolean isOutOfBounds(int[] coords) {
  return coords[0] == -1 || coords[1] == -1;
}

void drawCursor(int[] cursor, float scale) {
  ellipseMode(CENTER);
  stroke(0, 200, 0);
  ellipse(cursor[0], cursor[1], 5*scale, 5*scale);
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
  for (int i = 0; i < histogramWidth; i+=2) {
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
  float amplified = k*change;
  
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
      
      
      r = (int)(r + amplified);
      g = (int)(g + amplified);
      b = (int)(b + amplified);
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

void blur(PImage input, PImage output, int[] cursor, int radius) {

  input.loadPixels();
  output.loadPixels();

  int cX = cursor[0];
  int cY = cursor[1];

  for (int y = cY-radius; y < cY+radius; y++) 
  {
    for (int x = cX-radius; x < cX+radius; x++) 
    {
      //Check boundaries
      if (cX-radius-1 >= 0 && cX+radius+1 < input.width && 
      cY-radius-1 >= 0 && cY+radius+1 < input.height) 
      {
        float sumR = 0; 
        float sumG = 0;
        float sumB = 0;
        //Sum the surrounding pixels using the kernel matrix.
        for (int ky = -1; ky <= 1; ky++) 
        {
          for (int kx = -1; kx <= 1; kx++) 
          {
            int p = (y + ky)*input.width + (x + kx);

            float valR = red(input.pixels[p]);
            float valG = green(input.pixels[p]);
            float valB = blue(input.pixels[p]);

            sumR += kernel[ky+1][kx+1] * valR;
            sumG += kernel[ky+1][kx+1] * valG;
            sumB += kernel[ky+1][kx+1] * valB;
          }
        }
        output.pixels[y*input.width + x] = color(sumR, sumG, sumB);
      }
    }
  }
  output.updatePixels();
  input.updatePixels();
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
    "reset",
    offsetX, height - toolZoneHeight/2 - offsetY,
    toolZoneWidth,toolZoneHeight/2
  );
}
