tuioZoneTests
=============

imageManipulation
-----------------
This project is a deliverable for Aalto University course Experimental User Interfaces.

The demo is a simple image manipulation program that utilizes multitouch gestures for controlling image manipulation tools. The demo is implemented using the Processing programming language with tuioZones multitouch API.

In the default state, the image can be moved by with a single-point dragging gesture, and scaled using the two-point "pinch" gesture.

### Available tools

The demo includes three tools for adjusting the given sample image:

| Tool name      | Image |
| -------------- | ----- |
| Brightness     | ![brightness](imageManipulation/brightness.png)|
| Contrast       | ![contrast](imageManipulation/contrast.png)|
| Smudge         | ![smudge](imageManipulation/smudge.png)|

A tool is selected by touching the corresponding image and holding the touch. If the touch is released, no tool is selected and the image can be scaled and moved again. Whenever a tool is selected, a brightness histogram of the image is shown as an overlay.

When a tool is selected, any gestured applied on the image are overridden to follow the gestures mapped for the selected tool. Brightness and Contrast tools use a two-point rotation gesture to map the changes to the image. The Smudge tool uses a single point touch gesture.

Design Priciples
----------------

### Interaction Design
The ImageManipulation application is designed to follow the basic established touch-based interface conventions. Image position   

### Application Architecture
