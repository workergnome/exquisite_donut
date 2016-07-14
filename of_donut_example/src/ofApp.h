#pragma once

#include "ofMain.h"
#include "ofxOsc.h"
#include "particle.h"

#define HOST "192.168.1.255"
#define PORT 9000
#define ID_EXPIRATION_IN_SECONDS 10
#define MAXP 200
#define MINP 100
#define MAXC 10
#define MAXV 0.01
#define MAXA 0.001

class ofApp : public ofBaseApp{

  public:

		// Generic OF functions
		void setup();
		void update();
		void draw();

		// OF Events
		void windowResized(int w, int h);
		void keyPressed(int key);

		// OSC functionality
		ofxOscSender sender;
	  ofxOscReceiver receiver;
		void checkForMessages();
		void sendStatusMessage();
		void sendControlMessage();
		void handleStatusMessage(const ofxOscMessage &m);
		void handleControlMessage(const ofxOscMessage &m);
		void handleParticleMessage(const ofxOscMessage &m);

		// Utility functions
		void removeExpiredIds();
		uint64_t currentSecond();

		// Particle functions
		std::vector<Particle> particles;  // The vector of particles
		void generateParticles();
		void removeParticles();

		// Data Variables
	  int id;   												// The ID of this drawing
	  std::map<int, uint64_t> knownIds; // The IDs known to the system (if ID 0)
		uint64_t lastSecond;							// The last known second (for status pings)
		int generatedParticles;           // The # of particles generated this second
		
		// Received Control Variables
		int leftId;						 // The id to the left of the screen
		int rightId;					 // The id to the right of the screen
		int maxParticles;			 // The maximum number of particles allowed on screen
		int minParticles;			 // The minimum number of particles allowed on screen
		int maxNewParticles;	 // The # of particles allowed to appear per-second
		float maxVelocity;     // The maximum speed a particle can have
		float maxAcceleration; // The maximum accelleration for a particle
};
