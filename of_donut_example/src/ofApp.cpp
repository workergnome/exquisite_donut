#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){

  // Set up OSC receivers
  sender.setup(HOST, PORT);
  receiver.setup(PORT);

}

//--------------------------------------------------------------
void ofApp::update(){

  // Handle things that should occur once a second
  if (currentSecond() != lastSecond) {
    sendStatusMessage();
    if (id == 0) {
      sendControlMessage();
      removeExpiredIds();
    }
    lastSecond = currentSecond();
    generatedParticles = 0;
  }

  checkForMessages();

  // Update the particle system
  for (auto& p : particles) {
    p.update(maxVelocity,maxAcceleration);
  }
  generateParticles();
  removeParticles();
}

//--------------------------------------------------------------
void ofApp::draw(){
  for (auto& p : particles) { p.draw();}
}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){}
void ofApp::keyPressed(int key) { if (key == 32){id++;}}

//--------------------------------------------------------------
void ofApp::checkForMessages() {
  while(receiver.hasWaitingMessages()){

    ofxOscMessage m;
    receiver.getNextMessage(m);
        
    if (id == 0 && m.getAddress() == "/status") {
      handleStatusMessage(m);
    }    
    else if(m.getAddress() == "/control") {
     handleControlMessage(m);
    }
    else if(m.getAddress() == "/particle/" + ofToString(id)) {
      handleParticleMessage(m);
    }
  }
}

//--------------------------------------------------------------
void ofApp::sendStatusMessage() {

  ofxOscMessage m;
  m.setAddress("/status");
  m.addIntArg(id);
  m.addIntArg(particles.size());
  sender.sendMessage(m, false);
}

//--------------------------------------------------------------
void ofApp::sendControlMessage() {

  // If you haven't heard from anyone, don't send anything.
  if (knownIds.size() == 0)  { return; }

  // Generate the char array for IDs
  char data[255];
  int counter = 0;
  ofBuffer blobData;

  for (const auto& kv : knownIds) {
    data[counter] = (char)(kv.first);
    ++counter;
  }
  blobData.set(data, knownIds.size());

  // Send the OSC message
  ofxOscMessage m;
  m.setAddress("/control");
  m.addBlobArg(blobData);  
  m.addIntArg(MAXP);
  m.addIntArg(MINP);
  m.addIntArg(MAXC);
  m.addFloatArg(MAXV);
  m.addFloatArg(MAXA);
  sender.sendMessage(m, false);
}

//--------------------------------------------------------------
void ofApp::handleStatusMessage(const ofxOscMessage &m) {
  int statusId = m.getArgAsInt32(0);
  int particles = m.getArgAsInt32(1);
  knownIds[statusId] = currentSecond();
}

//--------------------------------------------------------------
void ofApp::handleParticleMessage(const ofxOscMessage &m) {
  int senderId = m.getArgAsInt32(0);

  Particle p;

  p.y = m.getArgAsFloat(1);
  p.xVel = m.getArgAsFloat(2);
  p.yVel = m.getArgAsFloat(3);
  p.xAcc = m.getArgAsFloat(4);
  p.yAcc = m.getArgAsFloat(5);
  p.free1 = m.getArgAsFloat(6);
  p.free2 = m.getArgAsFloat(7);

  // Figure out which side to put it on
  if (senderId == id && p.xVel > 0 ) {
    p.x = 0.0;
  }
  else if (senderId == id && p.xVel < 0 ) {
    p.x = 1.0;
  }
  else if (senderId == leftId ) {
    p.x = 0.0;
  }
  else if (senderId == rightId) {
    p.x = 1.0;
  }
  else {
    ofLog(OF_LOG_ERROR) << "Don't know what to do with a particle from " << senderId << "!";
    return;
  }

  particles.push_back(p);
}

//--------------------------------------------------------------
void ofApp::handleControlMessage(const ofxOscMessage &m) {
     
  ofBuffer data   = m.getArgAsBlob(0);     
  maxParticles    = m.getArgAsInt32(1);     
  minParticles    = m.getArgAsInt32(2);
  maxNewParticles = m.getArgAsInt32(3);
  maxVelocity     = m.getArgAsFloat(4);
  maxAcceleration = m.getArgAsFloat(5);

  // Calculate left and right IDs
  int val;
  int maxId = 0;
  leftId = 256;
  rightId = -1;
  for (int i = 0; i < data.size(); ++i) {
    val = (int)(data.getData()[i]);
    if (val > id && val < leftId) {
      leftId = val;
    }
    if (val < id && val > rightId) {
      rightId = val;
    }
    if (val > maxId) {
      maxId = val;
    }
  }
  if (leftId == 256) {
    leftId = 0;
  }
  if (rightId == -1) {
    rightId = maxId;
  }

  ofLogVerbose() << "My left ID is " << leftId << " and my right ID is " << rightId << ".";
}


void ofApp::generateParticles() {
  if (generatedParticles >= maxNewParticles) {return;}
  if (particles.size() >= maxParticles) {return;}

  Particle p;
  p.generate(maxVelocity, maxAcceleration);
  particles.push_back(p);
  generatedParticles++;

}

bool particleIsOffScreen(Particle p) { return p.isOffScreen();};

void ofApp::removeParticles() {
  for (auto& p : particles) {
    if (p.isOffScreen()){
      ofxOscMessage m = p.createOSCMessage(id);
      if (p.x < 0) {
        m.setAddress("/particle/" + ofToString(leftId));
      }
      else {
        m.setAddress("/particle/" + ofToString(rightId));  
      }
      sender.sendMessage(m, false);

    }
  }
 
  particles.erase(
    remove_if(particles.begin(), particles.end(), particleIsOffScreen),
  particles.end());
}

//--------------------------------------------------------------
void ofApp::removeExpiredIds() {

  int expiredTime = currentSecond();
  if (expiredTime <= ID_EXPIRATION_IN_SECONDS) {
    return;
  } else {
    expiredTime -= ID_EXPIRATION_IN_SECONDS;
  }

  for (auto iter = knownIds.begin(); iter != knownIds.end();) {
    if (iter->second < expiredTime) knownIds.erase(iter++);
    else ++iter;
  }
}

//--------------------------------------------------------------
uint64_t ofApp::currentSecond() {
  return ofGetElapsedTimeMillis()/1000;
}
