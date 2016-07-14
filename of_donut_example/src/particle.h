#pragma once
#include "ofMain.h"
#include "ofxOsc.h"


class Particle{
  public:
 
    // Constructors
    Particle(const ofxOscMessage &m, int id, int rightId);
    Particle(float maxVel, float maxAcc);
    
    // Standard OF functions
    void draw();
    void update(float maxVel, float maxAcc);
    
    // Custom functions
    ofxOscMessage createOSCMessage(int id, int leftId, int rightId);
    bool isOffScreen();
  
  protected:
    float x;
    float y;
    float xVel;
    float yVel;
    float xAcc;
    float yAcc;
    float free1;
    float free2;
};