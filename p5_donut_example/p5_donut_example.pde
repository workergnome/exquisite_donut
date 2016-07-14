import netP5.*;
import oscP5.*;

OscP5 osc;
int myID = 1;

ArrayList<Particle> particles = new ArrayList<Particle>();

//constants
//arraylist IDs
int MAXP = 0;
int MINP = 0;
int MAXC = 100;
float MAXV = 0.1;
float MAXA = 0.1;

int LEFTID = 0;
int RIGHTID = 0;


NetAddressList myNetAddressList = new NetAddressList();

int listenPort = 9000;
int broadcastPort = 9000;

String particlePattern = "/particle/1";

void setup(){
  fullScreen();
  osc = new OscP5(this, listenPort);
  frameRate(60);
}


void draw(){
  for(Particle p : particles){
    p.display();
  }
  
  for(int i = 0; i < particles.size(); i++) {
    if(particles.get(i).pos.x < 0) {
      
    }
  }
}


//OSC message handlers
void oscEvent(OscMessage theOscMessage) {
  
  //handle a new particle
  if(theOscMessage.addrPattern().equals(particlePattern)) {
    //create new particle, pulling from params of message
  
    PVector pos = new PVector();
    PVector vel = new PVector();
    PVector acc = new PVector();
    
    float free0 = 0;
    float free1 = 0;
    
    pos.y = map(theOscMessage.get(1).floatValue(), 0, 1, 0, height);
    vel.x = map(theOscMessage.get(2).floatValue(), 0, 1, 0, width);
    vel.y = map(theOscMessage.get(3).floatValue(), 0, 1, 0, height);
    acc.x = map(theOscMessage.get(4).floatValue(), 0, 1, 0, width);
    acc.y = map(theOscMessage.get(5).floatValue(), 0, 1, 0, height);
    
    free0 = theOscMessage.get(6).floatValue();
    free1 = theOscMessage.get(7).floatValue();
    
    if(vel.x > 0){
      pos.x = 0;
    } else if ( vel.x < 0) {
      pos.x = width;
    }
    
    Particle p = new Particle(pos, vel, acc);
    particles.add(p);
  }
    
  //handle a control message
  if(theOscMessage.addrPattern().equals("/control")){
    //update constants
    byte[] blob = theOscMessage.get(0).blobValue();
    MAXP = theOscMessage.get(1).intValue();
    MINP = theOscMessage.get(2).intValue();
    MAXC = theOscMessage.get(3).intValue();
    MAXV = map(theOscMessage.get(4).floatValue(), 0, 1, 0, width);
    MAXA = map(theOscMessage.get(5).floatValue(), 0, 1, 0, width); 
    
    int val;
    int maxId = 0;
    LEFTID = 256;
    RIGHTID -1;
    for(int i = 0; i < blob.size(); i++) {
      
      val = (int)blob[i];
      if(val > myID && val < LEFTID) {
        LEFTID = val;
      }
      if(val < myID && val > RIGHTID) {
        RIGHTID = val;
      }
      if (val > maxId) {
        maxId = val;
      }
    }
    
    if(LEFTID == 256) {
      LEFTID = 0;
    }
    if(RIGHTID == -1) {
      RIGHTID = maxId;
    }

  }
  
}