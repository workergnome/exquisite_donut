#pragma once
#include "ofMain.h"
#include "ofxOsc.h"


class Sprinkle{
  public:
 
    // Constructors
    Sprinkle(const ofxOscMessage &m);
    Sprinkle(float maxVel, float maxAcc);
    
    // Standard OF functions
    void draw();
    void update(float maxVel, float maxAcc);
    
    // Custom functions
    ofxOscMessage createOSCMessage() const;
    bool isOffScreen();
    
    float getX() const {return x;};
    float getY() const {return y;};

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