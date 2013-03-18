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

Following Processing.org conventions, the application is structured using a division of logic into a "setup" phase and a "draw" cycle. The latter consists of procedures for drawing the background and the image with the applied transformation properties and checking for tool selections. If a tool is found to be selected, a control layer for the tool is created and activated, and the selection of other tools disabled. While active, all gestures applied on the image are transformed into image adjustment effects based on the selected tool. 

Gesture recognition is implemented using the tuioZones API. There is a zone for handling the image translations alone. Additionally, a zone for each tool is created when the tool is selected. When the tool is deselected, the corresponding gesture tracking zone (tuioZone instance) is destroyed, allowing the base image translation zone to receive gestures again. 

Attempts have been made to keep the function names descriptive and the logic in key functions, such as `draw`, short.
