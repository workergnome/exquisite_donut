#pragma once
#include "ofMain.h"
#include "ofxOsc.h"
#include "sprinkle.h"

#define HOST "192.168.1.255"
#define PORT 9000
#define ID_EXPIRATION_IN_SECONDS 10
#define MAXP 200
#define MINP 100
#define MAXC 10
#define MAXV 0.01
#define MAXA 0.001

class DonutCop {
    // OSC functionality
    
    public:
      DonutCop();
      void update(int size);

      void broadcastSprinkle(const Sprinkle &p);
      void mentionNewSprinkle();
      bool allowedToCreateSprinkle(int sprinkleCount);
      bool hasNewSprinkles();
      Sprinkle getSprinkle();

      // Getters
      int maxSprinkles()      const { return _maxSprinkles;    };  
      int minSprinkles()      const { return _minSprinkles;    };  
      int maxNewSprinkles()   const { return _maxNewSprinkles; };  
      float maxVelocity()     const { return _maxVelocity;     };  
      float maxAcceleration() const { return _maxAcceleration; };  

      // Setters
      void setId(int _id)           { id = _id;                };

    protected:

      // Internal Functions
      uint64_t currentSecond();
      void sendStatusMessage(int size);
      void sendControlMessage();
      void removeExpiredIds();
      void checkForMessages();
      void handleStatusMessage(const ofxOscMessage &m);
      void handleControlMessage(const ofxOscMessage &m);
      void handleSprinkleMessage(const ofxOscMessage &m);

      // Internal Variables
      ofxOscSender sender;              // The OSC broadcaster
      ofxOscReceiver receiver;          // The OSC reciever
      std::map<int, uint64_t> knownIds; // The IDs known to the system (if ID 0)
      uint64_t lastSecond;              // The last known second (for status pings)
      int createdSprinkles;             // The # of sprinkles created during this second
      int id;                           // The ID of this drawing
      int leftId;                       // The id to the left of the screen
      int rightId;                      // The id to the right of the screen
      std::vector<Sprinkle> sprinkles;  // The vector of new sprinkles

      // Received Control Variables
      int _maxSprinkles;      // The maximum number of sprinkles allowed on screen
      int _minSprinkles;      // The minimum number of sprinkles allowed on screen
      int _maxNewSprinkles;   // The # of sprinkles allowed to appear per-second
      float _maxVelocity;     // The maximum speed a sprinkle can have
      float _maxAcceleration; // The maximum accelleration for a sprinkle

};