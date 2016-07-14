class Particle {
  
  PVector pos;
  PVector vel;
  PVector acc;
  float size;
  float alpha;
  
  
  Particle ( PVector _pos, PVector _vel, PVector _acc) {
    pos = _pos;
    vel = _vel;
    acc = _acc;
    
  }
  
  
  void update() {
    vel.add(acc);
    pos.add(vel);
    
  }
  
  void display() {
    
    fill(0, map(alpha, 0, 1, 0, 255));
    ellipse(pos.x, pos.y, size, size);
    
    
  }
  
}