class Boid
{
  private PVector position;
  private PVector velocity;
  private PShape shape;
  private float speed;
  
  private float radiusCone;
  private float heightCone;
  private float hypothenuse;
  
  private float avgHeadingWeight;
  private float avgPosWeight;
  private float avgAvoidanceWeight;
  
  private float invertedHeadingWeight;
  private float invertedPosWeight;
  private float invertedAvoidanceWeight;
  
  
  private float slowWeight;
  
  public Boid(PVector pos, float speed)
  {
    position = pos;//.add(new PVector(0,0,-50));
    this.speed = speed;
    velocity = PVector.random3D().mult(speed);
    
    // For testing:
    //position = new PVector(-30, -30, 0);
    //velocity = new PVector(1,0,0).mult(speed);
    
    radiusCone = 1.0;
    heightCone = 2.5;
    
    // calculated once for optimization in rayIntersect
    hypothenuse =  sqrt(radiusCone * radiusCone + heightCone * heightCone);

    shape = cone(new PVector(0,0,0), radiusCone, heightCone, 32);
    
    // in range [0,1]
    avgHeadingWeight = 0.010;//0.03;
    avgPosWeight = 0.010;//0.010;
    avgAvoidanceWeight = 0.015;//0.015;
    
    invertedHeadingWeight = 1 - avgHeadingWeight;
    invertedPosWeight = 1 - avgPosWeight;
    invertedAvoidanceWeight = 1 - avgAvoidanceWeight;
    
    slowWeight = 0.4;
    
  }
  public void draw()
  {
    pushMatrix();
    translate(position.x, position.y, position.z);

    // Rotates towards the negative of velocity.
    // Courtesy of Beta's answer https://stackoverflow.com/questions/1251828/calculate-rotations-to-look-at-a-3d-point
    rotateX(-atan2(-velocity.y, -velocity.z));
    rotateY(atan2(-velocity.x, sqrt(velocity.y*velocity.y+velocity.z*velocity.z)));

    shape(shape);
    popMatrix();
    
    //stroke(255);
    //drawLine(position, PVector.add(position, velocity.copy().normalize().mult(heightCone*2)));
  }
  public void update(PVector avgLocalHeading, PVector avgGlobalPos, PVector avgAvoidance)
  {
    PVector oldVelocity = velocity.copy();
    avgLocalHeading.mult(speed);
    velocity = PVector.add(avgLocalHeading.mult(avgHeadingWeight), velocity.mult(invertedHeadingWeight));
    
    if(velocity.mag() > speed);
      velocity.normalize().mult(speed);
    
    velocity = PVector.add(avgAvoidance.mult(avgAvoidanceWeight), velocity.mult(invertedAvoidanceWeight));
    if(velocity.mag() > speed);
      velocity.normalize().mult(speed);
    
    PVector diffGlobalPos = PVector.sub(avgGlobalPos, position).div(10);
    
    velocity = PVector.add(diffGlobalPos.mult(avgPosWeight), velocity.mult(invertedPosWeight));
    if(velocity.mag() > speed);
      velocity.normalize().mult(speed);
      
    // An idea, slow down if the velocty did not change a lot
    // Difficult to see how this works.
    float slowAngle = abs(atan2(-velocity.cross(oldVelocity).mag() , -velocity.dot(oldVelocity)));
    
    // the smaller the angle, the smaller the slow factor, the bigger (1-slowfactor)
    float slowFactor = map(slowAngle, 0, TWO_PI, 0, 1);
    
    velocity.mult( abs(1 - (slowFactor*slowWeight)));
    
    position.add(velocity);
  }
  public PVector getPosition()
  {
    return position.copy();
  }
  public PVector getVelocity()
  {
    return velocity.copy();
  }
  public PVector rayIntersect(PVector rayOrigin, PVector rayDir)
  {
    // A modified version of https://stackoverflow.com/questions/34157690/points-of-intersection-of-vector-with-cone
    // With some extra checks
    
    // Was initially used with the algorithm in testConeIntersect() to check for nearby boids with raycasting
    // But I switched to just checking the difference between the origins of closeby boids for simplicity/speed
    
    PVector conePoint = PVector.add(position, (velocity.copy()).normalize().mult(heightCone));
    PVector axis = PVector.sub(position, conePoint);
    PVector theta = axis.copy().normalize();
    float m = (radiusCone*radiusCone) / (axis.mag()*axis.mag());
    PVector w = PVector.sub(rayOrigin, conePoint);
    
    float a = rayDir.dot(rayDir) - (m * rayDir.dot(theta) * rayDir.dot(theta)) - (rayDir.dot(theta) * rayDir.dot(theta));
    float b = 2.0 * ( rayDir.dot(w) - (m * rayDir.dot(theta) * w.dot(theta)) - (rayDir.dot(theta) * w.dot(theta)) );
    
    float c = w.dot(w) - (m * w.dot(theta) * w.dot(theta)) - (w.dot(theta) * w.dot(theta));
    
    float discriminant = b*b - (4.0*a*c);
    
    if(discriminant >= 0)
    {
      PVector hitPos1 = rayOrigin.copy().add( rayDir.copy().normalize().mult( (-b - sqrt(discriminant)) / (2*a)) );
      
      PVector hitPos2 = rayOrigin.copy().add( rayDir.copy().normalize().mult( (-b + sqrt(discriminant)) / (2*a)) );
      
      boolean consider1 = !(PVector.sub(hitPos1,  conePoint).dot(theta) <= 0) && !(PVector.sub(hitPos1, conePoint).mag() > hypothenuse);
      
      boolean consider2 = !(PVector.sub(hitPos2,  conePoint).dot(theta) <= 0) && !(PVector.sub(hitPos2, conePoint).mag() > hypothenuse);
      
      if(consider1 && consider2)
        return (hitPos1.mag() < hitPos2.mag() ? hitPos1 : hitPos2);
      else if(consider1)
        return hitPos1;
      else if(consider2)
        return hitPos2;
    }
    return null;
  }
}


// One day maybe add this to shapes with the rayintersect
PShape cone(PVector org, float r, float h, int reso)
{
  if(reso < 3)
    reso = 3;
  float angle = TWO_PI/float(reso);
  PShape cone = createShape();
  cone.beginShape(TRIANGLES);
  cone.noStroke();
  cone.fill(255);

  for(int i=0;i<reso;i++)
  {
    PVector n1 = new PVector(-cos(i*angle), 0, -sin(i*angle)).normalize();
    PVector n3 = new PVector(-cos((i+1)*angle), 0, -sin((i+1)*angle)).normalize();
    
    PVector n2 = PVector.add(n1,n3).mult(0.5).normalize();
    
    cone.normal(-n1.x, -n1.z, n1.y);
    cone.vertex(org.x + cos(i*angle)*r, org.z + sin(i*angle)*r, org.y);
    
    cone.normal(-n2.x, -n2.z, n2.y);
    cone.vertex(org.x, org.z, org.y-h);
    
    cone.normal(-n3.x, -n3.z, n3.y);
    cone.vertex(org.x + cos((i+1)*angle)*r, org.z + sin((i+1)*angle)*r, org.y);

    // base
    cone.normal(0,0,1);
    
    cone.vertex(org.x + cos(i*angle)*r, org.z + sin(i*angle)*r, org.y);
    cone.vertex(org.x, org.z, org.y);
    cone.vertex(org.x + cos((i+1)*angle)*r, org.z + sin((i+1)*angle)*r, org.y);
    
    

  }
  cone.endShape();
  return cone;
}
