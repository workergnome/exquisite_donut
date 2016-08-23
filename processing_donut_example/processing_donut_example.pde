// Necessary for exquisite donut to work
DonutCop cop;
SprinkleManager sprinkles;

// Other global variables
PFont font;
int counter = 0;
float maxY;

void setup() {
    // Necessary for exquisite donut to work
    int ID = 0;
    // Your IP might be different than this one
    String broadastAddress = "10.0.0.255";
    cop = new DonutCop(ID, broadastAddress);
    sprinkles  = new SprinkleManager();
    
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
    PVector vel = new PVector(1*(random(.005)+.005),0);
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
    // Make a random sprinkle every second if the cop allows it
    if(counter%60 ==0){
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
        p.acc.y = .0002;   
    }
}

void updateSprinkles(){
    // Update donut_cop object and load received messages
    cop.update(sprinkles.size());
    // Add new sprinkles
    while(cop.hasNewSprinkles()){
        // Get next sprinkle
        Sprinkle p = cop.getNextSprinkle();
        // Add it to the scene
        sprinkles.add(p);
    }
    // Update sprinkles
    for(int i= 0; i<sprinkles.size(); i++){
        Sprinkle p = sprinkles.get(i);
        // Move sprinkles
        try{ p.update(cop.maxVelocity(),cop.maxAcceleration()); }
        // Safely remove sprinkles that for some reason don't update (usually a bad message)
        catch(Exception e){
          sprinkles.removeSafe(p);
          println("FOUND A MALFORMED SPRINKLE AT" + i);
          // Skip this loop iteration
          continue;
        }
        // Draw sprinkles
        drawSprinkle(p);
        // Apply physics to sprinkles for next frame
        sprinklePhysics(p);
        // Publish sprinkles that are outside screen and mark them for deletion
        if(p.pos.x > 1 || p.pos.x < 0){
            cop.broadcastSprinkle(p);
            sprinkles.removeSafe(p);
        }
    }
    // Actually remove sprinkles marked for deletion
    sprinkles.clearRemoved();
}