FirstPersonPerspective fpp;

Boid[] boid;
int nBoid = 200;
float boidSpeed = 0.4;

float checkDistanceHeading = 15;

float checkDistanceCollision = 10;

final PVector nullVec = new PVector(0,0,0);

Selectable cage;
int cageSize = 100;

void setup()
{
  fullScreen(P3D, 1);
  frameRate(60);
  
  fpp = new FirstPersonPerspective(this);
  //fpp.toggle();
  
  fixPerspective();
  
  fill(255);
  //noStroke();
  boid = new Boid[nBoid];
  for(int i=0;i<nBoid;i++)
    boid[i] = new Boid(PVector.random3D().mult(50), boidSpeed);
  
  fill(100,100,255, 100);
  stroke(255);
  cage = new Box( new PVector(-cageSize/2, cageSize/2, cageSize/2), cageSize, cageSize, cageSize);
}
// Changes the Frustum such that the near plane is closer to the camera, allowing the camera to get closer before clipping objects in the near plane.
public void fixPerspective()
{
  float cameraFOV = 60 * DEG_TO_RAD; // at least for now
  float cameraY = height / 2.0f;
  float cameraZ = cameraY / ((float) Math.tan(cameraFOV / 2.0f));
  float cameraNear = cameraZ / 100.0f;
  float cameraFar = cameraZ * 10.0f;
  float cameraAspect = (float) width / (float) height;
  
  perspective(cameraFOV, cameraAspect, cameraNear, cameraFar);
}

void draw()
{
  background(0);
    
  directionalLight(200, 200, 200, 0, 1, -1);
  ambientLight(60,60,60);
  
  noStroke();
  
  PVector averagePos = nullVec.copy();
  
  for(int i=0;i<nBoid;i++)
  {
    boid[i].draw();
    averagePos.add(boid[i].getPosition());
  }
  
  // Cage HAS to be drawn after boids for transparency ordering
  ((Box)cage).draw();

  
  PVector totalAvoidVector = nullVec.copy();
  PVector totalHeadingVector;
  
  averagePos.div(nBoid);

  // These updates are asynchronous, meaning after Boid[i] has been updated, all Boid[i+n] are updated according to Boid[i]'s updated value
  // Maybe add buffer to changes for synchronous update.
  for(int i=0;i<nBoid;i++)
  {
    totalHeadingVector = nullVec.copy();
    for(int j=0;j<nBoid;j++)
    {
      if(i==j)
        continue;
        
      PVector distance = PVector.sub(boid[i].getPosition(), boid[j].getPosition());
      
      PVector distancePointOrg = PVector.sub(PVector.add(boid[i].getPosition(), PVector.mult(boid[i].getVelocity().normalize(), 2.5)), boid[j].getPosition()); // magic 2.5 is height of cone
      if(distance.mag() <= checkDistanceHeading)
        totalHeadingVector.add(boid[j].getVelocity());
        
      if(distancePointOrg.mag() <= checkDistanceCollision)     
        totalAvoidVector.add(distance.normalize().mult( map( distance.mag(), 0, checkDistanceCollision, 0 , 1) ));

    }
    
    totalAvoidVector.add(avoidCage(boid[i]));
    totalHeadingVector.normalize();
    totalAvoidVector.normalize();

    boid[i].update(totalHeadingVector, averagePos, totalAvoidVector);
  }
  fpp.update();
}

PVector avoidCage(Boid b)
{
  PVector[] cardinalDirection =
  {
    new PVector(0,-1,0), // UP
    new PVector(0,1,0),  // DOWN
    new PVector(-1,0,0), // LEFT
    new PVector(1,0,0),  // RIGHT
    new PVector(0,0,-1), // FORWARD
    new PVector(0,0,1)   // BACKWARD
  };
  
  PVector avoidCage = nullVec.copy();
  
  for(int i=0;i<6;i++)
  {
    PVector hit = cage.rayIntersect(b.getPosition(), cardinalDirection[i]);
    if(hit != null)
    {
      PVector distance = PVector.sub(b.getPosition(), hit);
      if(distance.mag() <= 10)
        avoidCage.add(distance.normalize().mult( map( distance.mag(), 0, 10, 0 , boidSpeed*1000) )); // We really want to avoid the boids exiting the cage
    }
  }
  return avoidCage;
}

// Used to test if the rayIntersect for cones work, which does work but is ultimately not used for simplicity/speed reasons
// Picks numSpheres amount of points on a sphere
// Distributes them evenly on the sphere according to FNords answer on  https://stackoverflow.com/questions/9600801/evenly-distributing-n-points-on-a-sphere
// Then compares the points with FoV, which creates a cone-like shape of points representing the field of view of the boid:
//    FoV = 1 : 360 degrees
//    FoV = 0.5: 180 degrees
//    FoV = 0.2: 72 degrees
// If the point falls within this FoV, a raycast is done using this point as a sample
void testConeIntersect()
{
  fill(255);
  noStroke();
  
  int numSpheres = 201;
  float offset = 2.0/(float)numSpheres;
  float increment = PI * (3.0 - sqrt(5.0));
  float FoV = 0.7;
  float realFoV = FoV*2-1;
  
  for (int i = 0; i < numSpheres; i++)
  {
    float y = (((i * offset) - 1) + (offset / 2.0));
    //y = 0;
    float ra = sqrt(1.0 - pow(y,2));

    float phi = ((i + 1) % numSpheres) * increment;

    float x = cos(phi) * ra;
    float z = sin(phi) * ra;
    
    if(z < realFoV)
    {
      x*=-1;
      //y*=-1;
      z*=-1;
      
      for(int j=0;j<nBoid;j++)
      {
        PVector hit = boid[j].rayIntersect(nullVec.copy(), new PVector(x,y,z).normalize());
        
        if(hit != null)
        {
          
          stroke(255,0,0);
          drawLine(nullVec.copy(), hit);
          
          noStroke();
          fill(255,0,0);
          pushMatrix();
          translate(hit.x, hit.y, hit.z);
          box(2);
          popMatrix();
        }
      }
    }
  }
}

void drawLine(PVector v1, PVector v2)
{
  line(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
}
void keyPressed()
{
  fpp.keyPressed();
      
  if(key == 'g')
    for(int i=0;i<nBoid;i++)
      boid[i] = new Boid(PVector.random3D().mult(15), boidSpeed);
}
void keyReleased()
{
  fpp.keyReleased();
}
