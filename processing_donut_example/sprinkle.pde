class Sprinkle {

    PVector pos;
    PVector vel;
    PVector acc;
    float free1;
    float free2;

    Sprinkle ( PVector _pos, PVector _vel, PVector _acc, float _free1, float _free2) {
        pos = _pos;
        vel = _vel;
        acc = _acc;
        free1 = _free1;
        free2 = _free2;
        
    }

    void update(float maxVel, float maxAcc) {
        vel.limit(maxVel);
        acc.limit(maxAcc);
        pos.add(vel);
        vel.add(acc);
    }

    OscMessage createOSCMessage() {
        OscMessage m = new OscMessage(0);
        m.add(pos.y);
        m.add(vel.x);
        m.add(vel.y);
        m.add(acc.x);
        m.add(acc.y);
        m.add(free1);
        m.add(free2);
        return m;
    }

    boolean SprinkleisOffScreen() {
        return pos.x > 1 || pos.x < 0;
    }
}