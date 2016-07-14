#include "donut_cop.h"

//--------------------------------------------------------------
DonutCop::DonutCop() {
  sender.setup(HOST, PORT);
  receiver.setup(PORT);
}

//--------------------------------------------------------------
void DonutCop::update(int size) {
  if (currentSecond() != lastSecond) {
    sendStatusMessage(size);
    if (id == 0) {
      sendControlMessage();
      removeExpiredIds();
    }
    lastSecond = currentSecond();
    createdSprinkles = 0;
  }
  checkForMessages();
}

//--------------------------------------------------------------
void DonutCop::broadcastSprinkle(const Sprinkle &p) {
  ofxOscMessage m = p.createOSCMessage(id,leftId,rightId);
  sender.sendMessage(m, false);
}

//--------------------------------------------------------------
bool DonutCop::allowedToCreateSprinkle(int sprinkleCount) {
  if (createdSprinkles >= maxNewSprinkles()) {return false;}
  if (sprinkleCount >= maxSprinkles())       {return false;}
  return true;
}

//--------------------------------------------------------------
void DonutCop::mentionNewSprinkle() {
  createdSprinkles++; 
}

//--------------------------------------------------------------
bool DonutCop::hasNewSprinkles() {
  return sprinkles.size();
}

//--------------------------------------------------------------
Sprinkle DonutCop::getSprinkle() {
  Sprinkle p = sprinkles.back();
  sprinkles.pop_back();
  return p;
}

/***************************************************************
*                    PRIVATE FUNCTIONS                         *
***************************************************************/

void DonutCop::sendStatusMessage(int size) {
  ofxOscMessage m;
  m.setAddress("/status");
  m.addIntArg(id);
  m.addIntArg(size);
  sender.sendMessage(m, false);
}

//--------------------------------------------------------------
void DonutCop::sendControlMessage() {

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
uint64_t DonutCop::currentSecond() {
  return ofGetElapsedTimeMillis()/1000;
}

//--------------------------------------------------------------
void DonutCop::removeExpiredIds() {

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
void DonutCop::checkForMessages() {
  while(receiver.hasWaitingMessages()){

    ofxOscMessage m;
    receiver.getNextMessage(m);
        
    if (id == 0 && m.getAddress() == "/status") {
      handleStatusMessage(m);
    }    
    else if(m.getAddress() == "/control") {
     handleControlMessage(m);
    }
    else if(m.getAddress() == "/sprinkle/" + ofToString(id)) {
      handleSprinkleMessage(m);
    }
  }
}


//--------------------------------------------------------------
void DonutCop::handleStatusMessage(const ofxOscMessage &m) {
  int statusId = m.getArgAsInt32(0);
  int sprinkles = m.getArgAsInt32(1);
  knownIds[statusId] = currentSecond();
  ofLogVerbose() << "Received an update from ID " << statusId << ": it has " << sprinkles << " sprinkles.";
}

//--------------------------------------------------------------
void DonutCop::handleSprinkleMessage(const ofxOscMessage &m) {
  Sprinkle p(m, id, rightId);
  sprinkles.push_back(p);
}

//--------------------------------------------------------------
void DonutCop::handleControlMessage(const ofxOscMessage &m) {
     
  ofBuffer data   = m.getArgAsBlob(0);     
  _maxSprinkles    = m.getArgAsInt32(1);     
  _minSprinkles    = m.getArgAsInt32(2);
  _maxNewSprinkles = m.getArgAsInt32(3);
  _maxVelocity     = m.getArgAsFloat(4);
  _maxAcceleration = m.getArgAsFloat(5);

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

