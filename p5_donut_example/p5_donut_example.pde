DonutCop cop;
ArrayList<Sprinkle> sprinkles;
IntList sprinklesToRemove;

PFont font;

void setup() {
    //fullScreen();
    smooth(2);
    size(640,480,P2D);
    frameRate(60);
    cop = new DonutCop();
    sprinkles  = new ArrayList<Sprinkle>();
    font = createFont("Arial Bold",48);
    noStroke();
    sprinklesToRemove = new IntList();
}

int counter = 0;

void draw() {
    // Do all background stuff here
    background(0);
    // Update and draw sprinkles
    updateSprinkles();
    if(counter%10 ==0){
        produceRandomSprinkle();   
    }
    counter++;
    textFont(font,36);
    fill(255);
    text(str(int(frameRate))+" " + sprinkles.size(),20,60);
}

void drawSprinkle(Sprinkle p) {
    int size = 50;
    float xBorder = .1;
    float yBorder = -.1;
    float xPos = (p.pos.x-xBorder)*width*(1+xBorder*2);
    float yPos = (p.pos.y+yBorder)*height+(1+yBorder*2);
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

    for(int i= 0; i<sprinkles.size(); i++){
        Sprinkle p = sprinkles.get(i);
        p.update(cop.maxVelocity(),cop.maxAcceleration());
        drawSprinkle(p);
        sprinklePhysics(p);
        if(p.pos.x > 1){
            sprinklesToRemove.append(i);
        }
    }
    sprinklesToRemove.sortReverse();
    while(sprinklesToRemove.size()>0){
        int idx = sprinklesToRemove.get(0);
        Sprinkle p = sprinkles.get(idx);
        cop.broadcastSprinkle(p);
        sprinkles.remove(p);
        sprinklesToRemove.remove(0);
    }
    // Remove overflow sprinkles
    while(sprinkles.size() > cop.maxSprinkles()){
         sprinkles.remove(0);
    }
}

void produceRandomSprinkle(){
    PVector pos = new PVector(0,random(1));
    PVector vel = new PVector(random(.005)+.005,0);
    PVector acc = new PVector(0,0);
    Sprinkle p = new Sprinkle(pos,vel,acc, 0, 0);
    cop.broadcastSprinkle(p);
}