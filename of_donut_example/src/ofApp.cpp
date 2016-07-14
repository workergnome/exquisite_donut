#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
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
    createdParticles = 0;
  }

  checkForMessages();

  // Update the particle system
  for (auto& p : particles) {
    p.update(maxVelocity,maxAcceleration);
  }
  createParticles();
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

  Particle p(m, id, rightId);
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


void ofApp::createParticles() {
  if (createdParticles >= maxNewParticles) {return;}
  if (particles.size() >= maxParticles)    {return;}

  Particle p(maxVelocity, maxAcceleration);
  particles.push_back(p);
  createdParticles++;
}


void ofApp::removeParticles() {

  // Loop through and broadcast offscreen particles
  for (auto& p : particles) {
    if (p.isOffScreen()){
      ofxOscMessage m = p.createOSCMessage(id,leftId,rightId);
      sender.sendMessage(m, false);
    }
  }
  
  // Loop through and remove offscreen particles 
  particles.erase(
    remove_if(particles.begin(), particles.end(), [](Particle p) { return p.isOffScreen();}),
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
