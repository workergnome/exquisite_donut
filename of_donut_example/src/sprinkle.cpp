#include "sprinkle.h"

//--------------------------------------------------------------
// Generate the sprinkle with random parameters
Sprinkle::Sprinkle(float maxVel, float maxAcc) {

  maxY = float(ofGetHeight()) / float(ofGetWidth());

  x = ofRandomuf();
  y = ofMap(ofRandomuf(),0.0,1.0,0.0,maxY);
  xVel = ofRandomf() * maxVel;
  yVel = ofRandomf() * maxVel;
  xAcc = ofRandomf() * maxAcc;
  yAcc = ofRandomf() * maxAcc;
  free1 = ofRandomuf();
  free2 = ofRandomuf();
}

//--------------------------------------------------------------
// Generate the sprinkle from an OSC message
Sprinkle::Sprinkle(const ofxOscMessage &m) {

  maxY = float(ofGetHeight()) / float(ofGetWidth());

  x = 0;
  y = m.getArgAsFloat(0);
  xVel = m.getArgAsFloat(1);
  yVel = m.getArgAsFloat(2);
  xAcc = m.getArgAsFloat(3);
  yAcc = m.getArgAsFloat(4);
  free1 = m.getArgAsFloat(5);
  free2 = m.getArgAsFloat(6);

  // Handle starting on the right
  if (xVel < 0 ) { x = 1.0;}
}

//--------------------------------------------------------------
void Sprinkle::update(float maxVel, float maxAcc) {
  
  // bounce off top and bottom
  if (y >= maxY || y <= 0.0) {
    yVel *= -1.0;
    yAcc *= -1.0;
  }

  x += xVel;
  y += yVel;
  xVel += xAcc;
  xVel += yAcc;
  xVel = ofClamp(xVel,-maxVel, maxVel);
  yVel = ofClamp(yVel, -maxVel, maxVel);
  xAcc = maxAcc*ofRandomf();
  yAcc = maxAcc*ofRandomf();
}

//--------------------------------------------------------------
void Sprinkle::draw() {
  ofFill();
  ofSetColor(ofMap(free1,0.0,1.0,0,255));
  float xPos = ofMap(x,0.0, 1.0, 0.0, ofGetWidth());
  float yPos = ofMap(y,0.0, maxY, 0.0, ofGetHeight());
  ofDrawCircle(xPos,yPos,ofMap(free2,0.0,1.0,1,10));
}

//--------------------------------------------------------------
bool Sprinkle::isOffScreen() {
  return x > 1 || x < 0;
}

//--------------------------------------------------------------
ofxOscMessage Sprinkle::createOSCMessage() const {

  ofxOscMessage m;
  m.addFloatArg(y);
  m.addFloatArg(xVel);
  m.addFloatArg(yVel);
  m.addFloatArg(xAcc);
  m.addFloatArg(yAcc);
  m.addFloatArg(free1);
  m.addFloatArg(free2);
  return m;
}