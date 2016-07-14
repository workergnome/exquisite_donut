import netP5.*;
import oscP5.*;

OscP5 osc;
String myID = "1";

ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Integer> idList = new ArrayList<Integer>();

//constants
//arraylist IDs
int MAXP = 0;
int MINP = 0;
int MAXC = 100;
float MAXV = 0.1;
float MAXA = 0.1;



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
  
  
  
}


void oscEvent(OscMessage theOscMessage) {
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
    
 
  
  if(theOscMessage.addrPattern().equals("/control")){
    //update constants
    
  }
  
}