class Particle {
  PVector position;
  float lifespan;
  float radius;
  float weight;
  float maxcolor;

  Particle(PVector l) {
    radius = 450;
    weight = 25;
    position = l.copy();
    lifespan = 100.0;
    maxcolor = max(heartNew[0], heartNew[1]);
  }

  void run() {
    update();
    display();
  }

  // method to update position
  void update() {
    radius += 25;
    lifespan -= 5.0;
    weight -= 0.5;
  }

  // method to display
  void display() {
    stroke(maxcolor, 100, 100, lifespan);
    weight = lerp(weight, weight -= 0.5, 0.2);
    strokeWeight(weight);
    noFill();
    //fill(255, lifespan);
    radius = lerp(radius, radius += 25, 0.2);
    ellipse(position.x, position.y, radius, radius);
  }

  // is the particle still useful?
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}