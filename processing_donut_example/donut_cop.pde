import netP5.*;
import oscP5.*;

// TODO: 
// Add automatic ID recognition
// Update KnownIDs correctly
// Figure out HOST 


public class TimeStampedID {
    long timeStamp;
    int id;
    TimeStampedID(int _id, long _timeStamp) {
        timeStamp = _timeStamp;
        id = _id;
    }
    // Hash by ID so there can be no duplicates
    @Override
        public int hashCode() {
        int result = id;
        return result;
    }
    // Compare by ID not by timestamp
    @Override
        public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (!TimeStampedID.class.isAssignableFrom(obj.getClass())) {
            return false;
        }
        final TimeStampedID other = (TimeStampedID) obj;
        if (this.id != other.id) {
            return false;
        }
        return true;
    }
}

class DonutCop {
    // Global variables
    String HOST = "localHost";//"10.0.0.87";
    int PORT = 9000;
    int ID_EXPIRATION_IN_SECONDS = 10;
    OscP5 osc;

    // Internal variables
    private int lastSecond = 0;         // The last known second (for status pings)
    private int createdSprinkles;        // The # of sprinkles created during this second
    private int id;                      // The ID of this drawing
    private int leftId = 0;                  // The id to the left of the screen
    private int rightId = 0;                 // The id to the right of the screen
    // Received Control Variables
    private int _maxSprinkles = 200;      // The maximum number of Sprinkles allowed on screen
    private int _minSprinkles = 0;      // The minimum number of Sprinkles allowed on screen
    private int _maxNewSprinkles = 10;   // The # of Sprinkles allowed to appear per-second
    private float _maxVelocity = 0.02;     // The maximum speed a sprinkle can have
    private float _maxAcceleration = 0.001; // The maximum accelleration for a sprinkle
    // Known ID's
    private ArrayList<TimeStampedID> knownIDs;
    // Sprinkle buffer
    private ArrayList<Sprinkle> sprinkleBuffer= new ArrayList<Sprinkle>();
    NetAddress controlAddress = new NetAddress("192.168.1.255", PORT);
    NetAddressList nodeAddresses = new NetAddressList();


    // Useful functions
    DonutCop(int _id) {
        id = _id;
        // Setup osc
        OscProperties properties = new OscProperties();
        properties.setListeningPort(PORT);
        properties.setRemoteAddress(HOST, PORT);
        osc = new OscP5(this, properties);
        // Custom listener for debugging purposes
        OscListener t = new OscListener();
        osc.addListener(t);
        knownIDs = new ArrayList<TimeStampedID>();
    }

    void update(int size) {
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
    private int currentSecond() {
        return millis()/1000;
    }
    // Function to remove expired IDs
    private void removeExpiredIds() {

        int expiredTime = currentSecond();
        if (expiredTime <= ID_EXPIRATION_IN_SECONDS) {
            return;
        } else {
            expiredTime -= ID_EXPIRATION_IN_SECONDS;
        }
        // loop through backwards so we don't get indexing errors
        for (int i = knownIDs.size()-1; i>=0; i--) {
            if (knownIDs.get(i).timeStamp - expiredTime < 0) {
                println("Deleting ID" + knownIDs.get(i));
                knownIDs.remove(i);
            }
        }
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
    // Function to broadcast new sprinkle message
    void broadcastSprinkle(Sprinkle p) {
        OscMessage m = p.createOSCMessage();
        String address = "/sprinkle/" + str((p.pos.x < 0) ? leftId : rightId);
        m.setAddrPattern(address);
        osc.send(m,controlAddress);
    }
    // Function to broadcast a status message
    private void sendStatusMessage(int size) {
        OscMessage m = new OscMessage("/status");
        m.add(id);
        m.add(size);
        osc.send(m, controlAddress);
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
            data[i] = (byte)knownIDs.get(i).id;
        }
        // Calculate my own IDs because I won't be listening to /control
        CalculateIDs(data);
        OscMessage m = new OscMessage("/control");
        m.add(data);
        m.add(_maxSprinkles);
        m.add(_minSprinkles);
        m.add(_maxNewSprinkles);
        m.add(_maxVelocity);
        m.add(_maxAcceleration);
        osc.send(m, controlAddress);
    }
    // Function to receive status message
    private void handleStatusMessage(OscMessage m) {
        println("Got status");
        int statusId = m.get(0).intValue();
        int sprinkles = m.get(1).intValue();
        TimeStampedID newID = new TimeStampedID(statusId, currentSecond());
        int idx = knownIDs.indexOf(newID);
        if (idx>=0) {
            knownIDs.set(idx, newID);
        } else {
            knownIDs.add(newID);
        }
        println("Received an update from ID " + statusId + ": it has " + sprinkles + " sprinkles.");
    }
    // Function to receive control message
    private void handleControlMessage(OscMessage m) {
        byte[] data    = m.get(0).blobValue();     
        _maxSprinkles    = m.get(1).intValue();     
        _minSprinkles    = m.get(2).intValue();
        _maxNewSprinkles = m.get(3).intValue();
        _maxVelocity     = m.get(4).floatValue();
        _maxAcceleration = m.get(5).floatValue();
        println("max_sprinkles " + _maxSprinkles + " min_sprinkles " + _minSprinkles);
        CalculateIDs(data);
    }
    
    private void CalculateIDs(byte[] data){
        // Calculate left and right IDs
        int val;
        int minID = 256;
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
            if (val < minID) {
                minID = val;
            }
        }
        if (leftId == 256) {
            leftId = (id == 0) ? minID : 0;
        }
        if (rightId == -1) {
            rightId = maxId;
        }
        println("My left ID is " + str(leftId) + " and my right ID is " + str(rightId) +  ".");
    }
    
    // Function to receive a new sprinkle message
    private void handleSprinkleMessage(OscMessage m) {
        PVector pos = new PVector();
        PVector vel = new PVector();
        PVector acc = new PVector();
        //pos.x = 0
        pos.y = m.get(0).floatValue();
        vel.x = m.get(1).floatValue();
        vel.y = m.get(2).floatValue();
        acc.x = m.get(3).floatValue();
        acc.y = m.get(4).floatValue();
        if(vel.x > 0) pos.x = 0;
        else pos.x = 1;
        float free1 =1; // m.get(5).floatValue();
        float free2 = 1; //m.get(6).floatValue();
        Sprinkle p = new Sprinkle(pos, vel, acc, free1, free2);
        sprinkleBuffer.add(p);
    }
    // Added a custom listener for debugging purposes
    class OscListener implements OscEventListener {
        public void oscEvent(OscMessage m) {
            if (id == 0 && m.addrPattern().equals("/status")) {
                handleStatusMessage(m);
            }
            if (id != 0 && m.addrPattern().equals("/control")) {
                handleControlMessage(m);
            }
            if (m.addrPattern().equals("/sprinkle/" + str(id))) {
                handleSprinkleMessage(m);
            }
        }

        public void oscStatus(OscStatus theStatus) {
            println("osc status : "+theStatus.id());
        }
    }
}