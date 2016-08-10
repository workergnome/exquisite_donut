// Necessary for exquisite donut to work
DonutCop cop;
ArrayList<Sprinkle> sprinkles;
IntList sprinklesToRemove;

// Other global variables
PFont font;
int counter = 0;

void setup() {
    // Necessary for exquisite donut to work
    cop = new DonutCop();
    sprinkles  = new ArrayList<Sprinkle>();
    sprinklesToRemove = new IntList();
    // Other properties
    smooth(2);
    size(640,480,P2D);
    frameRate(60);
    font = createFont("Arial Bold",48);
    noStroke();
}

// Testing function to initialize random sprinkles
void produceRandomSprinkle(){
    PVector pos = new PVector(0,random(1));
    PVector vel = new PVector(random(.005)+.005,0);
    PVector acc = new PVector(0,0);
    Sprinkle p = new Sprinkle(pos,vel,acc, 0, 0);
    cop.broadcastSprinkle(p);
}

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
    float xBorder = -.1;
    float yBorder = .1;
    float xPos = (1-xBorder*2)*p.pos.x*width+width*(xBorder);
    float yPos = (1-yBorder*2)*p.pos.y*height+height*(yBorder);
    fill(255,p.pos.y*255.0,p.pos.x*255.0);
    ellipse(xPos,yPos, size, size);
}

void sprinklePhysics(Sprinkle p) {
    // Reverse velocity if position is out of bounds
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
        // Move sprinkles
        p.update(cop.maxVelocity(),cop.maxAcceleration());
        // Draw sprinkles
        drawSprinkle(p);
        // Apply physics to sprinkles for next frame
        sprinklePhysics(p);
        // Set to remove and publish sprinkles that are outside screen
        if(p.pos.x > 1 || p.pos.x < 0){
            sprinklesToRemove.append(i);
        }
    }
    // Sort descending to not screw up our indexing
    sprinklesToRemove.sortReverse();
    // Remove and publish sprinkles set for deletion
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