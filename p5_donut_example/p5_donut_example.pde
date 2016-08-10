DonutCop cop;
ArrayList<Sprinkle> sprinkles;

void setup() {
    //fullScreen();
    size(640,480);
    frameRate(60);
    cop = new DonutCop();
    sprinkles  = new ArrayList<Sprinkle>();
}

int counter = 0;

void draw() {
    // Do all background stuff here
    //background(255);
    // Update and draw sprinkles
    updateSprinkles();
    if(counter%300 == 0){
        produceRandomSprinkle();
        
    }
    counter++;
}

void drawSprinkle(Sprinkle p) {
    int size = 50;
    float xBorder = .1;
    float yBorder = .1;
    float xPos = (p.pos.x-xBorder)*width*(1+xBorder*2);
    float yPos = (p.pos.y-yBorder)*height+(1+yBorder*2);
    fill(255,p.pos.y*255.0,p.pos.x*255.0);
    ellipse(xPos,yPos, size, size);
}

void sprinklePhysics(Sprinkle p) {
    
    if(p.pos.y<0){
       p.vel.y = Math.abs(p.vel.y);
    }
    else if(p.pos.y>1){
       p.vel.y = Math.abs(p.vel.y)*-1;
    }
    else{
     p.acc.y = .0002;   
    }
}

void updateSprinkles(){
    // Add new sprinkles
    while(cop.hasNewSprinkles()){
        Sprinkle p = cop.getNextSprinkle();
        sprinkles.add(p);
    }
    // Remove overflow sprinkles
    while(sprinkles.size() > cop.maxSprinkles()){
         sprinkles.remove(0);
    }
    for(int i= 0; i<sprinkles.size(); i++){
        Sprinkle p = sprinkles.get(i);
        p.update(cop.maxVelocity(),cop.maxAcceleration());
        drawSprinkle(p);
        sprinklePhysics(p);
        if(p.pos.x > 1){
            cop.broadcastSprinkle(p);
            sprinkles.remove(p);
        }
    }
}

void produceRandomSprinkle(){
    PVector pos = new PVector(0,random(1));
    PVector vel = new PVector(random(.005)+.005,0);
    PVector acc = new PVector(0,0);
    Sprinkle p = new Sprinkle(pos,vel,acc, 0, 0);
    cop.broadcastSprinkle(p);
}