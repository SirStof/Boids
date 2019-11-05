import java.awt.Robot;
import java.awt.Rectangle;
import java.awt.AWTException;
import processing.core.PApplet;

class FirstPersonPerspective extends PApplet
{
  private float x, y, z;
  private float cx, cy, cz;
  private float sensitivity, angleH, angleV;
  private int middleX, middleY;
  private boolean forward, backward, left, right, up, down;
  private float movementSpeed;
  private boolean controlMouse;
  private Robot robot;
  private PApplet parent;
  
  public FirstPersonPerspective(PApplet p)
  {
    try
    {
      robot = new Robot();
    }
    catch (AWTException e)
    {
      e.printStackTrace();
    }
    parent = p;
    //home();
    
    x = 0;
    y = 0;
    z = 150;
    cy = y;
    cz = z - 1;
    cx = x;
    angleH = -60;
    angleV = 135;

    sensitivity = 0.25;
    middleX = parent.width/2;
    middleY = parent.height/2;
    forward = backward = left = right = up = down = false;
    movementSpeed = 3;
    controlMouse = false;
    robot.mouseMove(middleX, middleY);
  }
  void home()
  {
    x = 0;
    y = 0;
    z = 150;
    cy = y;
    cz = z - 1;
    cx = x;
    angleH = 180;
    angleV = 0;
  }
  void update()
  {
    if(!controlMouse)
    {
      parent.camera(x,y,z, cx,cy,cz, 0,1,0);
      return;
    }

    robot.mouseMove(middleX, middleY);

    // Move player
    PVector frontV = new PVector(cx,cy,cz);
    frontV.sub(new PVector(x, y, z));
    frontV.setMag(movementSpeed);
    PVector rightV = new PVector(frontV.x, frontV.z);
    rightV.rotate(PI/2.0);
    rightV.setMag(movementSpeed);
    if(forward)
    {
      x += frontV.x;
      y += frontV.y;
      z += frontV.z;
    }
    if(backward)
    {
      x -= frontV.x;
      y -= frontV.y;
      z -= frontV.z;
    }
    if(left)
    {
      x -= rightV.x;
      z -= rightV.y;
    }
    if(right)
    {
      x += rightV.x;
      z += rightV.y;
    }
    if(up)
      y -= movementSpeed;
    if(down)
      y += movementSpeed;

    float changeH = middleX - parent.mouseX;
    changeH *= sensitivity;
    float changeV = -(middleY - parent.mouseY);
    changeV *= sensitivity;
    
    angleH += changeH;
    angleH = angleH % 360;
    
    if(angleV + changeV < 85 && angleV + changeV > -85)
      angleV += changeV;
    else if(angleV + changeV > 85)
      angleV = 85;
    else if(angleV + changeV < -85)
      angleV = -85;

    cx = sin(radians(angleH))*cos(radians(angleV)) + x;
    cy = sin(radians(angleV)) + y;
    cz = cos(radians(angleH))*cos(radians(angleV)) + z;

    parent.camera(x,y,z, cx,cy,cz, 0,1,0);
  }
  public void setPos(float xNew, float yNew, float zNew)
  {
    x = xNew;
    y = yNew;
    z = zNew;
  }
  public void lookAt(float cxNew, float cyNew, float czNew)
  {
    // TODO implement?
  }
  void setMovementSpeed(float newMS)
  {
    movementSpeed = newMS;
  }
  float getMovementSpeed()
  {
    return movementSpeed;
  }
  void setSensitivity(float newSens)
  {
    sensitivity = newSens;
  }
  float getSensitivity()
  {
    return sensitivity;
  }
  public void enable()
  {
    controlMouse = true;
    parent.noCursor();
  }
  public void disable()
  {
    controlMouse = false;
    parent.cursor(ARROW);
  }
  public void toggle()
  {
    if(controlMouse)
      disable();
    else
      enable();
  }
  void keyPressed()
  {
    if(parent.key == 'w')
      forward = true;
    if(parent.key == 's')
      backward = true;
    if(parent.key == 'a')
      left = true;
    if(parent.key == 'd')
      right = true;
    if(parent.keyCode == 32) // 32 is spacebar
      up = true;
    if(parent.key == 'c')
      down = true;
      
    if(parent.key == 'r')
      home();
      
    if(parent.key == '`')
      toggle();
  }
  void keyReleased()
  {
    if(parent.key == 'w')
      forward = false;
    if(parent.key == 's')
      backward = false;
    if(parent.key == 'a')
      left = false;
    if(parent.key == 'd')
      right = false;
    if(parent.keyCode == 32) // 32 is spacebar
      up = false;
    if(parent.key == 'c')
      down = false;
  }
  public PVector getLookAtVector()
  {
    return (PVector.sub(new PVector(cx, cy, cz), new PVector(x,y,z))).normalize();
  }
  public PVector getPos()
  {
    return new PVector(x,y,z);
  }
}
