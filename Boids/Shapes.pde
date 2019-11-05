interface Selectable
{
  public PVector rayIntersect(PVector rayOrigin, PVector rayDir);
}

class Triangle implements Selectable
{
  private PVector vert1, vert2, vert0;
  private PVector normal;
  private PVector midPoint;
  private PShape shape;
  
  private float x,y,z;

  public Triangle(PVector v0, PVector v1, PVector v2) // point first specified will be the 'origin'
  {
    vert1 = v1;
    vert2 = v2;
    vert0 = v0;
    
    x = v0.x;
    y = v0.y;
    z = v0.z;
    
    midPoint = new PVector( (vert0.x+vert1.x+vert2.x)/3.0, (vert0.y+vert1.y+vert2.y)/3.0, (vert0.z+vert1.z+vert2.z)/3.0 );
    
    /*midPoint.x -= x;
    midPoint.y -= y;
    midPoint.z -= z;*/
    
    shape = createShape();
    shape.beginShape(TRIANGLES);
    /*shape.vertex(vert0.x, vert0.y, vert0.z);
    shape.vertex(vert1.x, vert1.y, vert1.z);
    shape.vertex(vert2.x, vert2.y, vert2.z);*/
    
    shape.vertex(0, 0, 0);
    shape.vertex(vert1.x - vert0.x, vert1.y - vert0.y, vert1.z - vert0.z);
    shape.vertex(vert2.x - vert0.x, vert2.y - vert0.y, vert2.z - vert0.z);
    
    shape.endShape();
    
    PVector edge1 = PVector.sub(vert1, vert0);
    PVector edge2 = PVector.sub(vert2, vert0);
    
    normal = (edge2.cross(edge1)).normalize();
  }
  public PShape getShape()
  {
    return shape;
  }
  public PVector getNormal()
  {
    return normal;
  }
  public PVector rayIntersect(PVector rayOrigin, PVector rayDir)
  {
    float error = 1e-7;
    PVector edge1 = PVector.sub(vert1, vert0);
    PVector edge2 = PVector.sub(vert2, vert0);
    PVector h = rayDir.cross(edge2);
    float a = edge1.dot(h);
    if(a > -error && a < error)
      return null;
    float f = 1.0/a;
    PVector s = PVector.sub(rayOrigin, vert0);
    float u = f * s.dot(h);
    if(u < 0.0 || u > 1.0)
      return null;
    PVector q = s.cross(edge1);
    float v = f * rayDir.dot(q);
    if(v < 0.0 || u + v > 1.0)
      return null;
    float t = f * edge2.dot(q);
    if(t > error)
      return PVector.add(rayOrigin, PVector.mult(rayDir, t));
    return null;
  }
  public PVector getMiddle()
  {
    return midPoint;
  }
  
  public void move(PVector offset)
  {
    x += offset.x;
    y += offset.y;
    z += offset.z;
    
    vert1.x += offset.x;
    vert1.y += offset.y;
    vert1.z += offset.z;
    
    vert2.x += offset.x;
    vert2.y += offset.y;
    vert2.z += offset.z;
    
    vert0.x += offset.x;
    vert0.y += offset.y;
    vert0.z += offset.z;
  }
  
  public void draw()
  {
    pushMatrix();
    translate(x,y,z);
    shape(shape);
    popMatrix();
  }
}



class Quad implements Selectable
{
  private Triangle tri0, tri1;
  private PShape shape;
  
  private float x,y,z;
  
  public Quad(PVector v0, PVector v1, PVector v2, PVector v3) // left bottom, left top, right top, right bottom.
  {
    tri0 = new Triangle(v0, v1, v2);
    tri1 = new Triangle(v0, v2, v3);
    
    x = v0.x;
    y = v0.y;
    z = v0.z;
    
    shape = createShape(GROUP);
    shape.addChild(tri0.getShape());
    shape.addChild(tri1.getShape());
  }
  public PShape getShape()
  {
    return shape;
  }
  public PVector rayIntersect(PVector rayOrigin, PVector rayDir) // maybe an optimized intersect exists for quads?
  {
    PVector hit0 = tri0.rayIntersect(rayOrigin, rayDir);
    if(hit0 != null)
      return hit0;
    PVector hit1 = tri1.rayIntersect(rayOrigin, rayDir);
    if(hit1 != null)
      return hit1;
    return null;
  }
  public PVector getNormal()
  {
    return tri0.getNormal();
  }
  public PVector getMiddle()
  {
    PVector mid0 = tri0.getMiddle();
    PVector mid1 = tri1.getMiddle();
    
    return new PVector((mid0.x+mid1.x)/2, (mid0.y+mid1.y)/2, (mid0.z+mid1.z)/2);
  }
  
  public void move(PVector offset)
  {
    x += offset.x;
    y += offset.y;
    z += offset.z;
    
    tri0.move(offset);
    tri1.move(offset);
  }
  
  public void draw()
  {
    pushMatrix();
    translate(x,y,z);
    shape(shape);
    popMatrix();
  }
}

class Box implements Selectable
{
  PShape shape;
  
  float x,y,z;
  
  Quad[] detectBox;
  
  public Box(PVector leftBot, float w, float d, float h)
  {
    x = leftBot.x;
    y = leftBot.y;
    z = leftBot.z;
    
    detectBox = new Quad[6]; // or 6 if you need to include the base of the box
    
    makeShape(w, d, h);
  }
  
  private void makeShape(float w, float d, float h)
  {
    //fill(0,255,0);
    this.shape = createShape(BOX, w, h, d);
    this.shape.translate(w/2,-h/2,-d/2);
    
    
    // base left bot (x+w,y,z)
    // base left top (x+w,y,z+d)
    // base right top (x,y,z+d)
    // base right bot (x,y,z)
    // 
    // top left bot (x+w,y-h,z)
    // top left top (x+w,y-h,z+d)
    // top right top (x,y-h,z+d)
    // top right bot (x,y-h,z)
    
    //shape = createShape(GROUP);
    // No one sees the base
    Quad base = new Quad(new PVector(x,y,z), new PVector(x,y,z-d), new PVector(x+w,y,z-d), new PVector(x+w,y,z));
    detectBox[0] = base;
    //shape.addChild(base.getShape());
    
    //fill(0,255,0);
    Quad front = new Quad(new PVector(x+w,y,z), new PVector(x+w,y-h,z), new PVector(x,y-h,z), new PVector(x,y,z));
    detectBox[1] = front;
    //shape.addChild(front.getShape());
    
    Quad back = new Quad(new PVector(x,y,z-d), new PVector(x,y-h,z-d), new PVector(x+w,y-h,z-d), new PVector(x+w,y,z-d));
    //back.getShape().translate(0,0,-d);
    detectBox[2] = back;
    //shape.addChild(back.getShape());
    
    Quad right = new Quad(new PVector(x+w,y,z), new PVector(x+w,y-h,z), new PVector(x+w,y-h,z-d), new PVector(x+w,y,z-d));
    //right.getShape().translate(w,0,0);
    detectBox[3] = right;
    //shape.addChild(right.getShape());
    
    Quad left = new Quad(new PVector(x,y,z), new PVector(x,y-h,z), new PVector(x,y-h,z-d), new PVector(x,y,z-d));
    detectBox[4] = left;
    //shape.addChild(left.getShape());
    
    Quad top = new Quad(new PVector(x,y-h,z), new PVector(x,y-h,z-d), new PVector(x+w,y-h,z-d), new PVector(x+w,y-h,z));
    //top.getShape().translate(0,-h,0);
    detectBox[5] = top;
    //shape.addChild(top.getShape());
  }
  
  public void moveTo(PVector destination)
  {
    x = destination.x;
    y = destination.y;
    z = destination.z;
  }
  
  public void move(PVector offset)
  {
    x += offset.x;
    y += offset.y;
    z += offset.z;
    
    for(int i=0;i<detectBox.length;i++)
      detectBox[i].move(offset);
  }

  public PVector rayIntersect(PVector rayOrigin, PVector rayDir)
  {
    PVector cur = null;
    for(int i=0;i<detectBox.length;i++)
    {
      PVector hit = detectBox[i].rayIntersect(rayOrigin, rayDir);
      if(hit != null)
      {
        if(cur == null)
          cur = hit;
        else if(PVector.sub(rayOrigin, hit).mag() < PVector.sub(rayOrigin, cur).mag())
          cur = hit;
      }
    }
    return cur;
  }
  public void draw()
  {
    pushMatrix();
    translate(x,y,z);
    shape(shape);
    
    
    /*for(int i=0;i<detectBox.length;i++)
      shape(detectBox[i].getShape());*/
    popMatrix();
  }
}



class Sphere implements Selectable
{
  private PShape shape;
  private float x,y,z;
  
  private int reso;
  private float r;
  
  private final float PHI = (float)((sqrt(5) + 1.0) / 2.0);
  private final int[] baseT = new int[]
  {
      0,2,1, 0,3,2, 0,4,3, 0,5,4, 0,1,5,
      1,2,7, 2,3,8, 3,4,9, 4,5,10, 5,1,6,
      1,7,6, 2,8,7, 3,9,8, 4,10,9, 5,6,10,
      11,6,7, 11,7,8, 11,8,9, 11,9,10, 11,10,6
  };
  
  private PVector[][] verts;
  private int[][] triangles;
  
  private PVector[] baseVerts;
  
  public Sphere(float x, float y, float z, float radi)
  {
    r = radi;
    reso = 8;
    
    this.x = x;
    this.y = y;
    this.z = z;
    
    baseVerts = new PVector[12];
    baseVerts[0] = new PVector(-1f, PHI, 0f);
    baseVerts[1] = new PVector(1f, PHI, 0f);
    baseVerts[2] = new PVector(0f, 1f, PHI);
    baseVerts[3] = new PVector(-PHI, 0f, 1f);
    baseVerts[4] = new PVector(-PHI, 0f, -1f);
    baseVerts[5] = new PVector(0f, 1f, -PHI);
    baseVerts[6] = new PVector(PHI, 0f, -1f);
    baseVerts[7] = new PVector(PHI, 0f, 1f);
    baseVerts[8] = new PVector(0f, -1f, PHI);
    baseVerts[9] = new PVector(-1f, -PHI, 0f);
    baseVerts[10] = new PVector(0f, -1f, -PHI);
    baseVerts[11] = new PVector(1f, -PHI, 0f);
    
    for(int i=0;i<baseVerts.length;i++)
      baseVerts[i].normalize();
      
      
    verts = new PVector[20][];
    triangles = new int[20][];
    
    makeShape();
  }
  
  public void makeShape()
  {
    shape = createShape();
    shape.beginShape(TRIANGLE);

    for(int i=0;i<20;i++)
    {
      PVector[] vertices = new PVector[3];
      //int[] triangles = new int[] { 0, 1, 2 };
      for (int j = 0; j < 3; j++)
          vertices[j] = baseVerts[baseT[3 * i + j]];
          
      makePartShape(vertices, i); 
      fillShape(i);
    }
    shape.endShape();
    shape.scale(r);
  }
  private void makePartShape(PVector[] baseTriangle, int arrOffset)
  {
    verts[arrOffset] = new PVector[(reso + 1) * (reso + 2) / 2];
    triangles[arrOffset] = new int[reso * reso * 3];
    PVector up = (PVector.sub(baseTriangle[1], baseTriangle[0])).div(reso);
    PVector right = (PVector.sub(baseTriangle[2], baseTriangle[1])).div(reso);
    int triIndex = 0;
    int i=0;
    
    for (int y = 0; y <= reso; y++)
    {
      PVector pointOnEdge = PVector.add(baseTriangle[0], PVector.mult(up, y));
      for (int x = 0; x <= y; x++)
      {
        PVector pointOnTriangle = PVector.add(pointOnEdge, PVector.mult(right, x));
        
        verts[arrOffset][i] = pointOnTriangle;
        verts[arrOffset][i].normalize();

        if (y != reso)
        {
          triangles[arrOffset][triIndex] = i;
          triangles[arrOffset][triIndex + 1] = i + y + 1;
          triangles[arrOffset][triIndex + 2] = i + y + 2;
          triIndex += 3;
        
          if(x != 0)
          {
            triangles[arrOffset][triIndex] = i;
            triangles[arrOffset][triIndex + 1] = i - 1;
            triangles[arrOffset][triIndex + 2] = i + y + 1;
            triIndex += 3;
          }
        }
        i++;
      }
    }
  }
  private void fillShape(int arrOffset)
  {
    for(int j=0;j<triangles[arrOffset].length;j+=3)
    {
      shape.vertex(verts[arrOffset][triangles[arrOffset][j]].x, verts[arrOffset][triangles[arrOffset][j]].y, verts[arrOffset][triangles[arrOffset][j]].z);
      shape.vertex(verts[arrOffset][triangles[arrOffset][j+1]].x, verts[arrOffset][triangles[arrOffset][j+1]].y, verts[arrOffset][triangles[arrOffset][j+1]].z);
      shape.vertex(verts[arrOffset][triangles[arrOffset][j+2]].x, verts[arrOffset][triangles[arrOffset][j+2]].y, verts[arrOffset][triangles[arrOffset][j+2]].z);
    }
  }
  public PShape getShape()
  {
    return shape;
  }
  public void move(PVector offset)
  {
    x += offset.x;
    y += offset.y;
    z += offset.z;
  }
  public PVector rayIntersect(PVector rayOrigin, PVector rayDir)
  {
    PVector spherePosVec = PVector.sub(new PVector(x, y, z), rayOrigin);
    float Tca = PVector.dot(spherePosVec, rayDir);
    
    if(Tca < 0)
      return null;
    
    float distSquared = PVector.dot(spherePosVec,spherePosVec) - Tca*Tca;
    if(distSquared > r*r)
      return null;
    
    float Thc = sqrt(r * r - distSquared);
    
    float tFront = Tca - Thc;
    //float tBack = Tca + Thc;
    
    return PVector.add(rayOrigin, PVector.mult(rayDir, tFront));
  }
  
  public void draw()
  {
    pushMatrix();
    translate(x,y,z);
    shape(shape);
    popMatrix();
  }
}
