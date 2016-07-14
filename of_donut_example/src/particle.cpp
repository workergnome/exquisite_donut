#include "particle.h"

//--------------------------------------------------------------
void Particle::update(float maxVel, float maxAcc) {
  
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
void Particle::draw() {
  ofFill();
  ofSetColor(ofMap(free1,0.0,1.0,0,255));
  float xPos = ofMap(x,0.0, 1.0, 0, ofGetWidth());
  float yPos = ofMap(y,0.0, 1.0, 0, ofGetHeight());
  ofDrawCircle(xPos,yPos,ofMap(free2,0.0,1.0,1,10));
}

//--------------------------------------------------------------
void Particle::generate(float maxVel, float maxAcc) {
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
bool Particle::isOffScreen() {
  return x > 1 || x < 0;
}

//--------------------------------------------------------------
ofxOscMessage Particle::createOSCMessage(int id) {

  ofxOscMessage m;
  m.addIntArg(id);
  m.addFloatArg(y);
  m.addFloatArg(xVel);
  m.addFloatArg(yVel);
  m.addFloatArg(xAcc);
  m.addFloatArg(yAcc);
  m.addFloatArg(free1);
  m.addFloatArg(free2);
  return m;
}