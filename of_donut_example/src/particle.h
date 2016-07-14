#pragma once
#include "ofMain.h"
#include "ofxOsc.h"


class Particle{
  public:
    float x;
    float y;
    float xVel;
    float yVel;
    float xAcc;
    float yAcc;
    float free1;
    float free2;

    void draw();
    void update(float maxVel, float maxAcc);
    void generate(float maxVel, float maxAcc);
    ofxOscMessage createOSCMessage(int id);
    bool isOffScreen();
};