/*
Brightness
This demo uses TUIO-based rotation gesture to increase 
and decrease brightness on an image. 
Shows a histogram overlay while adjusting. 
*/

import oscP5.*;
import netP5.*;
import tuioZones.*;

TUIOzoneCollection zones;

PImage img;
float tintValue;
float oldRot;
color histColor;

void setup() {
  size(640,573);
  tintValue = 255;
  
  zones=new TUIOzoneCollection(this);
  zones.setZone("image", 0,0,640,573);
  zones.setZone("gesture", 0,0,width,height);
  zones.setZoneParameter("image","DRAGGABLE",true);
  zones.setZoneParameter("image","THROWABLE",true);
  zones.setZoneParameter("image","SCALABLE",true);
  img = loadImage("butterfly.jpg");
  
  noFill();
  smooth();
  
  histColor = color(255,255,255, 100);
  
}

void drawHistogram (PImage img, color histColor) {
  int[] hist = new int[256];

  // Calculate the histogram
  for (int i = 0; i < img.width; i++) {
    for (int j = 0; j < img.height; j++) {
      int bright = int(brightness(get(i, j)));
      hist[bright]++; 
    }
  }
  
  // Find the largest value in the histogram
  int histMax = max(hist);
  
  stroke(histColor);
  for (int i = 0; i < img.width; i++) {
    // Map i (from 0..img.width) to a location in the histogram (0..255)
    int which = int(map(i, 0, img.width, 0, 255));
    // Convert the histogram value to a location between 
    // the bottom and the top of the picture
    int y = int(map(hist[which], 0, histMax, img.height, 0));
    line(i, img.height, i, y);
  }
}

void brightness(PImage img, float change) {
  //println(change);
  // amplification for the change
  float k = .2;
  
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++ ) {
      // Calculate the 1D pixel location
      int i = x + y*img.width;
      // Get the R,G,B values from image
      //int r = (int) red(img.pixels[i]);
      //int g = (int) green(img.pixels[i]);
      //int b = (int) blue(img.pixels[i]);
       
      // Much faster RGB values (uses bit-shifting)
      int r = (img.pixels[i] >> 16) & 0xFF; //like calling the function red(), but faster
      int g = (img.pixels[i] >> 8) & 0xFF;
      int b = img.pixels[i] & 0xFF; 
      
      
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
      //img.pixels[i] = c;
      
      // bitshift'd
      img.pixels[i]= 0xff000000 | (r << 16) | (g << 8) | b;
    }
  }
  img.updatePixels();
}

void draw(){

  background(0);
  
  // use the zone coordinates and size to display the image
  image(img, zones.getZoneX("image"),zones.getZoneY("image"),zones.getZoneWidth("image"),zones.getZoneHeight("image"));
  // outline photo when pressed
  if (zones.isZonePressed("gesture")) {
    
    drawHistogram(img, histColor);
    
    //stroke(200,200,0);
    //strokeWeight(4);
    rect(zones.getZoneX("image"),zones.getZoneY("image"),zones.getZoneWidth("image"),zones.getZoneHeight("image"));
    
    float rot = zones.getGestureRotation("gesture");
    
    // increase/decrease tint
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
      
      brightness(img, delta);
    }
    oldRot = rot;
  }
}


