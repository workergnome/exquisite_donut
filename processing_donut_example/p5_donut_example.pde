// Necessary for exquisite donut to work
DonutCop cop;
ArrayList<Sprinkle> sprinkles;
IntList sprinklesToRemove;

// Other global variables
PFont font;
int counter = 0;
float maxY;

void setup() {
    // Necessary for exquisite donut to work
    cop = new DonutCop(0);
    sprinkles  = new ArrayList<Sprinkle>();
    sprinklesToRemove = new IntList();
    // Other properties
    smooth(2);
    size(640,480,P2D);
    //fullScreen();
    frameRate(60);
    font = createFont("Courier New",48);
    noStroke();
    maxY = float(height)/width;
    println(maxY);
}

// Testing function to initialize random sprinkles
void produceRandomSprinkle(){
    PVector pos = new PVector(0,random(maxY));
    PVector acc = new PVector(0,0);
    Sprinkle p = new Sprinkle(pos,vel,acc, 0, 0);
    sprinkles.add(p);
    //cop.broadcastSprinkle(p);
    cop.mentionNewSprinkle();
}

void draw() {
    // Do all background stuff here
    background(0);
    // Update and draw sprinkles
    updateSprinkles();
    if(counter%1 ==0){
        if(cop.allowedToCreateSprinkle(sprinkles.size()))
          produceRandomSprinkle(); 
    }
    counter++;
    textFont(font,24);
    fill(255);
    text(str(int(frameRate))+" FPS, " + sprinkles.size()+" Sprinkles",20,60);
}

void drawSprinkle(Sprinkle p) {
    int ballSize = 50;
    float xBorder = -(float)ballSize/width/2;
    float yBorder = (float)ballSize/width/2;
    float xPos = (1-xBorder*2)*p.pos.x*width+width*(xBorder);
    float yPos = (1-yBorder*2)*p.pos.y*width+width*(yBorder);
    fill(255,p.pos.y*255.0,p.pos.x*255.0);
    ellipse(xPos,yPos, ballSize, ballSize);
}

void sprinklePhysics(Sprinkle p) {
    // Reverse velocity if position is out of bounds
    if(p.pos.y<0){
       p.vel.y = Math.abs(p.vel.y);
    }
    else if(p.pos.y>maxY){
       p.vel.y = Math.abs(p.vel.y)*-1;
    }
    else{
        // Positive acceleration because y goes 0-Max top to bottom
        //p.acc.y = .0002;   
    }
}

void updateSprinkles(){
    cop.update(sprinkles.size());
    // Add new sprinkles
    while(cop.hasNewSprinkles()){
        // Get next sprinkle
        Sprinkle p = cop.getNextSprinkle();
        // Check if we can add it
        sprinkles.add(p);
    }
    // Update sprinkles
    for(int i= 0; i<sprinkles.size(); i++){
        Sprinkle p = sprinkles.get(i);
        // Move sprinkles
        try{
        p.update(cop.maxVelocity(),cop.maxAcceleration()); }
        catch(Exception e){
          sprinkles.remove(p);
          println("FOUND A MALFORMED SPRINKLE AT" + i);
          continue;
        }
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
}