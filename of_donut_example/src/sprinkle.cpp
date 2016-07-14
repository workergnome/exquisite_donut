#include "sprinkle.h"

//--------------------------------------------------------------
// Generate the sprinkle with random parameters
Sprinkle::Sprinkle(float maxVel, float maxAcc) {
  x = ofRandomuf();
  y = ofRandomuf();
  xVel = ofRandomf() * maxVel;
  yVel = ofRandomf() * maxVel;
  xAcc = ofRandomf() * maxAcc;
  yAcc = ofRandomf() * maxAcc;
  free1 = ofRandomuf();
  free2 = ofRandomuf();
}

//--------------------------------------------------------------
// Generate the sprinkle from an OSC message
Sprinkle::Sprinkle(const ofxOscMessage &m, int id, int rightId) {
  x = 0;
  y = m.getArgAsFloat(1);
  xVel = m.getArgAsFloat(2);
  yVel = m.getArgAsFloat(3);
  xAcc = m.getArgAsFloat(4);
  yAcc = m.getArgAsFloat(5);
  free1 = m.getArgAsFloat(6);
  free2 = m.getArgAsFloat(7);

  // Handle starting on the right
  int senderId = m.getArgAsInt32(0);
  if (xVel < 0 ) { x = 1.0;}
}

//--------------------------------------------------------------
void Sprinkle::update(float maxVel, float maxAcc) {
  
  // bounce off top and bottom
  if (y >= 1.0 || y <= 0.0) {
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
  float xPos = ofMap(x,0.0, 1.0, 0, ofGetWidth());
  float yPos = ofMap(y,0.0, 1.0, 0, ofGetHeight());
  ofDrawCircle(xPos,yPos,ofMap(free2,0.0,1.0,1,10));
}

//--------------------------------------------------------------
bool Sprinkle::isOffScreen() {
  return x > 1 || x < 0;
}

//--------------------------------------------------------------
ofxOscMessage Sprinkle::createOSCMessage(int id,int leftId, int rightId) const {

  ofxOscMessage m;
  m.addIntArg(id);
  m.addFloatArg(y);
  m.addFloatArg(xVel);
  m.addFloatArg(yVel);
  m.addFloatArg(xAcc);
  m.addFloatArg(yAcc);
  m.addFloatArg(free1);
  m.addFloatArg(free2);
  string address = "/sprinkle/" + ofToString( (x < 0) ? leftId : rightId);
  m.setAddress(address);
  return m;
}