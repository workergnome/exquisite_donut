#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
  ofSetLogLevel(OF_LOG_VERBOSE);
  ofBackground(216,24,96);
};

//--------------------------------------------------------------
void ofApp::update(){

  donutCop.update(sprinkles.size());

  // Update the sprinkle system
  for (auto& p : sprinkles) {
    p.update(donutCop.maxVelocity(),donutCop.maxAcceleration());
  }

  // add new sprinkles from messages
  while (donutCop.hasNewSprinkles()) {
    sprinkles.push_back(donutCop.getSprinkle());
  }

  createSprinkles();
  removeSprinkles();
}

//--------------------------------------------------------------
void ofApp::draw(){
  for (auto& p : sprinkles) { p.draw();}
}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){}
void ofApp::keyPressed(int key) { if (key == 32){donutCop.setId(1);}}

//--------------------------------------------------------------
void ofApp::createSprinkles() {

  // Check with the donut cop if you're allowed to create a new sprinkle
  if (donutCop.allowedToCreateSprinkle(sprinkles.size())) {

    // Create a new sprinkle
    Sprinkle p(donutCop.maxVelocity(), donutCop.maxAcceleration());

    // Add it to the sprinkles list
    sprinkles.push_back(p);

    // Tell the cop that we created one, so it can keep track
    // of how many have been created. 
    donutCop.mentionNewSprinkle();
  }
}

//--------------------------------------------------------------
void ofApp::removeSprinkles() {

  // Loop through and broadcast offscreen sprinkles
  for (auto& p : sprinkles) {
    if (p.isOffScreen()){
      donutCop.broadcastSprinkle(p);
    }
  }
  
  // Loop through and remove offscreen sprinkles 
  sprinkles.erase(
    remove_if(sprinkles.begin(), sprinkles.end(), [](Sprinkle p) { return p.isOffScreen();}),
  sprinkles.end());
}