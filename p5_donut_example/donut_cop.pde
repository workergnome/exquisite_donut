import netP5.*;
import oscP5.*;

// TODO: 
// Add automatic ID recognition
// Update KnownIDs correctly
// Figure out HOST configuration

class DonutCop {
    // Global variables
    String HOST = "localHost";//"10.0.0.87";
    int PORT = 9000;
    int ID_EXPIRATION_IN_SECONDS = 10;
    OscP5 osc;

    // Internal variables
    private int lastSecond;         // The last known second (for status pings)
    private int createdSprinkles;        // The # of sprinkles created during this second
    private int id;                      // The ID of this drawing
    private int leftId;                  // The id to the left of the screen
    private int rightId;                 // The id to the right of the screen
    // Received Control Variables
    private int _maxSprinkles = 200;      // The maximum number of Sprinkles allowed on screen
    private int _minSprinkles = 0;      // The minimum number of Sprinkles allowed on screen
    private int _maxNewSprinkles = 10;   // The # of Sprinkles allowed to appear per-second
    private float _maxVelocity = 0.02;     // The maximum speed a sprinkle can have
    private float _maxAcceleration = 0.001; // The maximum accelleration for a sprinkle
    // Known ID's
    private IntList knownIDs = new IntList();
    // Sprinkle buffer
    private ArrayList<Sprinkle> sprinkleBuffer= new ArrayList<Sprinkle>();

    // Useful functions
    DonutCop() {
        id = 0;
        OscProperties properties = new OscProperties();
        properties.setListeningPort(PORT);
        properties.setRemoteAddress(HOST, PORT);
        osc = new OscP5(this, properties);
        // Custom listener for debugging purposes
        OscListener t = new OscListener();
        osc.addListener(t);
    }

    void update(int size) { //Unfinished
        if (currentSecond() != lastSecond) {
            sendStatusMessage(size);
            if (id == 0) {
                sendControlMessage();
                removeExpiredIds();
            }
            lastSecond = currentSecond();
            createdSprinkles = 0;
        }
    }
    // Not sure how this function is supposed to work
    private void removeExpiredIds() {

        int expiredTime = currentSecond();
        if (expiredTime <= ID_EXPIRATION_IN_SECONDS) {
            return;
        } else {
            expiredTime -= ID_EXPIRATION_IN_SECONDS;
        }

        //for (auto iter = knownIds.begin(); iter != knownIds.end();) {
        //  if (iter->second < expiredTime) knownIds.erase(iter++);
        //  else ++iter;
        //}
    }
    
    // Unsure why function exists or what createdSprinkles is meant to be
    // keeping track of. Why is it reset in the update function?
    void mentionNewSprinkle() {
        createdSprinkles++;
    }
    
    // Function to check if a sprinkle should be added to the scene
    boolean allowedToCreateSprinkle(int sprinkleCount) {
        if (createdSprinkles >= _maxNewSprinkles) {
            return false;
        }
        if (sprinkleCount >= _maxSprinkles) {
            return false;
        }
        return true;
    }
    // Check if there are sprinkles in the buffer
    boolean hasNewSprinkles() {
        return sprinkleBuffer.size() > 0;
    }
    // Returns a sprinkle and removes it from the buffer
    Sprinkle getNextSprinkle() {
        int idx = sprinkleBuffer.size()-1;
        Sprinkle p = sprinkleBuffer.get(idx);
        sprinkleBuffer.remove(idx);
        return p;
    }
    // Getter functions for private variables
    int maxSprinkles() { 
        return _maxSprinkles;
    }
    int minSprinkles() { 
        return _minSprinkles;
    }
    int maxNewSprinkles() { 
        return _maxNewSprinkles;
    }
    float maxVelocity() { 
        return _maxVelocity;
    }
    float maxAcceleration() { 
        return _maxAcceleration;
    }

    // Setter functions
    void setId(int _id) { 
        id = _id;
    };

    private int currentSecond() {
        return millis()/1000;
    }
    // Function to broadcast new sprinkle message
    void broadcastSprinkle(Sprinkle p) {
        OscMessage m = p.createOSCMessage();
        String address = "/sprinkle/" + str((p.pos.x < 0) ? leftId : rightId);
        m.setAddrPattern(address);
        osc.send(m);
    }
    // Function to broadcast a status message
    private void sendStatusMessage(int size) {
        OscMessage m = new OscMessage("/status");
        m.add(id);
        m.add(size);
        osc.send(m);
    }
    // Function to broadcast a control message
    private void sendControlMessage() {
        // If you haven't heard from anyone, don't send anything.
        if (knownIDs.size() == 0) { 
            return;
        }
        // Generate the byte array for IDs
        byte[] data = new byte[255];
        for (int i=0; i<knownIDs.size(); i++) {
            data[i] = (byte)knownIDs.get(i);
        }
        OscMessage m = new OscMessage("/control");
        data  = OscMessage.makeBlob(data);
        m.add(data);
        m.add(_maxSprinkles);
        m.add(_minSprinkles);
        m.add(_maxNewSprinkles);
        m.add(_maxVelocity);
        m.add(_maxAcceleration);
        osc.send(m);
    }
    // Function to receive status message
    private void handleStatusMessage(OscMessage m) {
        int statusId = m.get(0).intValue();
        int sprinkles = m.get(1).intValue();
        //knownIds[statusId] = currentSecond();
        //ofLogVerbose() << "Received an update from ID " << statusId << ": it has " << sprinkles << " sprinkles.";
    }
    // Function to receive control message
    private void handleControlMessage(OscMessage m) {
        byte[] data    = m.get(0).blobValue();     
        _maxSprinkles    = m.get(1).intValue();     
        _minSprinkles    = m.get(2).intValue();
        _maxNewSprinkles = m.get(3).intValue();
        _maxVelocity     = m.get(4).floatValue();
        _maxAcceleration = m.get(5).floatValue();
        // Calculate left and right IDs
        int val;
        int maxId = 0;
        leftId = 256;
        rightId = -1;
        for (int i = 0; i < data.length; ++i) {
            val = (char)(data[i]);
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
        print("My left ID is " + str(leftId) + " and my right ID is " + str(rightId) +  ".");
    }
    // Function to receive a new sprinkle message
    private void handleSprinkleMessage(OscMessage m) {
        PVector pos = new PVector();
        PVector vel = new PVector();
        PVector acc = new PVector();
        pos.x = 0;
        pos.y = m.get(0).floatValue();
        vel.x = m.get(1).floatValue();
        vel.y = m.get(2).floatValue();
        acc.x = m.get(3).floatValue();
        acc.y = m.get(4).floatValue();
        float free1 = m.get(5).floatValue();
        float free2 = m.get(6).floatValue();
        Sprinkle p = new Sprinkle(pos, vel, acc, free1, free2);
        sprinkleBuffer.add(p);
    }
    // Added a custom listener for debugging purposes
    class OscListener implements OscEventListener {
        public void oscEvent(OscMessage m) {
            if (id == 0 && m.addrPattern().equals("/status")) {
                handleStatusMessage(m);
            }
            if (id == 0 && m.addrPattern().equals("/control")) {
                handleControlMessage(m);
            }
            if (id == 0 && m.addrPattern().equals("/sprinkle/" + str(id))) {
                handleSprinkleMessage(m);
            }
        }

        public void oscStatus(OscStatus theStatus) {
            println("osc status : "+theStatus.id());
        }
    }
}