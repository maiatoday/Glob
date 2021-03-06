//The MIT License (MIT) - See Licence.txt for details

//Copyright (c) 2013 Mick Grierson, Matthew Yee-King, Marco Gillies


import org.jbox2d.util.nonconvex.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.testbed.*;
import org.jbox2d.collision.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.p5.*;
import org.jbox2d.dynamics.*;

// audio stuff

Maxim maxim;
AudioPlayer globSound, wallSound;
AudioPlayer[] jamSounds;
AudioPlayer[] spongeSounds;


Physics physics; // The physics handler: we'll see more of this later
// rigid bodies for the glob and two jamGlobs
Body glob;
Body [] jamGlobs;
int jamCount = 20;
Body [] sponges;
int spongeCount = 5;
// the start point of the catapult 
Vec2 startPoint;
// a handler that will detect collisions
CollisionDetector detector; 

int jamSize = 80;
int ballSize = 60;

PImage jamImage, globImage, tip;

int score = 0;

boolean dragging = false;

void setup() {
  size(1024,768);
  frameRate(60);


  tip = loadImage("boiling-water.jpg");
  jamImage = loadImage("j01.png");
  globImage = loadImage("glob.png");
  imageMode(CENTER);

  //initScene();

  /**
   * Set up a physics world. This takes the following parameters:
   * 
   * parent The PApplet this physics world should use
   * gravX The x component of gravity, in meters/sec^2
   * gravY The y component of gravity, in meters/sec^2
   * screenAABBWidth The world's width, in pixels - should be significantly larger than the area you intend to use
   * screenAABBHeight The world's height, in pixels - should be significantly larger than the area you intend to use
   * borderBoxWidth The containing box's width - should be smaller than the world width, so that no object can escape
   * borderBoxHeight The containing box's height - should be smaller than the world height, so that no object can escape
   * pixelsPerMeter Pixels per physical meter
   */
  physics = new Physics(this, width, height, 0, 0, width*2, height*2, width, height, 100);
  // this overrides the debug render of the physics engine
  // with the method myCustomRenderer
  // comment out to use the debug renderer 
  // (currently broken in JS)
  physics.setCustomRenderingMethod(this, "myCustomRenderer");
  physics.setDensity(10.0);

  // set up the objects
  // Rect parameters are the top left 
  // and bottom right corners
  jamGlobs = new Body[7];
  jamGlobs[0] = physics.createRect(600, height-jamSize, 600+jamSize, height);
  jamGlobs[1] = physics.createRect(600, height-2*jamSize, 600+jamSize, height-jamSize);
  jamGlobs[2] = physics.createRect(600, height-3*jamSize, 600+jamSize, height-2*jamSize);
  jamGlobs[3] = physics.createRect(600+1.5*jamSize, height-jamSize, 600+2.5*jamSize, height);
  jamGlobs[4] = physics.createRect(600+1.5*jamSize, height-2*jamSize, 600+2.5*jamSize, height-jamSize);
  jamGlobs[5] = physics.createRect(600+1.5*jamSize, height-3*jamSize, 600+2.5*jamSize, height-2*jamSize);
  jamGlobs[6] = physics.createRect(600+0.75*jamSize, height-4*jamSize, 600+1.75*jamSize, height-3*jamSize);

  startPoint = new Vec2(200, height-150);
  // this converst from processing screen 
  // coordinates to the coordinates used in the
  // physics engine (10 pixels to a meter by default)
  startPoint = physics.screenToWorld(startPoint);

  // circle parameters are center x,y and radius
  glob = physics.createCircle(width/2, -100, ballSize/2);

  // sets up the collision callbacks
  detector = new CollisionDetector (physics, this);

  maxim = new Maxim(this);
  globSound = maxim.loadFile("jam1.wav");
  wallSound = maxim.loadFile("sponge1.wav");

  globSound.setLooping(false);
  globSound.volume(1.0);
  wallSound.setLooping(false);
  wallSound.volume(1.0);
  // now an array of crate sounds
  jamSounds = new AudioPlayer[jamGlobs.length];
  for (int i=0;i<jamSounds.length;i++){
    String f = String.format("jam%d.wav", i);
    jamSounds[i] = maxim.loadFile(f);
    jamSounds[i].setLooping(false);
    jamSounds[i].volume(1);
  }

}

void draw() {
  image(tip, width/2, height/2, width, height);


  // we can call the renderer here if we want 
  // to run both our renderer and the debug renderer
  //myCustomRenderer(physics.getWorld());

  fill(0);
  text("Score: " + score, 20, 20);
}

void mouseDragged()
{
  // tie the glob to the mouse while we are dragging
  dragging = true;
  glob.setPosition(physics.screenToWorld(new Vec2(mouseX, mouseY)));
}

// when we release the mouse, apply an impulse based 
// on the distance from the glob to the catapult
void mouseReleased()
{
  dragging = false;
  Vec2 impulse = new Vec2();
  impulse.set(startPoint);
  impulse = impulse.sub(glob.getWorldCenter());
  impulse = impulse.mul(50);
  glob.applyImpulse(impulse, glob.getWorldCenter());
}

// this function renders the physics scene.
// this can either be called automatically from the physics
// engine if we enable it as a custom renderer or 
// we can call it from draw
void myCustomRenderer(World world) {
  stroke(0);

  Vec2 screenStartPoint = physics.worldToScreen(startPoint);
  strokeWeight(8);
  line(screenStartPoint.x, screenStartPoint.y, screenStartPoint.x, height);

  // get the globs position and rotation from
  // the physics engine and then apply a translate 
  // and rotate to the image using those values
  // (then do the same for the jamGlobs)
  Vec2 screenGlobPos = physics.worldToScreen(glob.getWorldCenter());
  float globAngle = physics.getAngle(glob);
  pushMatrix();
  translate(screenGlobPos.x, screenGlobPos.y);
  rotate(-radians(globAngle));
  image(globImage, 0, 0, ballSize, ballSize);
  popMatrix();


  for (int i = 0; i < jamGlobs.length; i++)
  {
    Vec2 worldCenter = jamGlobs[i].getWorldCenter();
    Vec2 jamPos = physics.worldToScreen(worldCenter);
    float jamAngle = physics.getAngle(jamGlobs[i]);
    pushMatrix();
    translate(jamPos.x, jamPos.y);
    rotate(-jamAngle);
    image(jamImage, 0, 0, jamSize, jamSize);
    popMatrix();
  }

  if (dragging)
  {
    strokeWeight(2);
    line(screenGlobPos.x, screenGlobPos.y, screenStartPoint.x, screenStartPoint.y);
  }
}

// This method gets called automatically when 
// there is a collision
void collision(Body b1, Body b2, float impulse)
{
  if ((b1 == glob && b2.getMass() > 0)
    || (b2 == glob && b1.getMass() > 0))
  {
    if (impulse > 1.0)
    {
      score += 1;
    }
  }

  // test for glob
  if (b1.getMass() == 0 || b2.getMass() == 0) {// b1 or b2 are walls
    // wall sound
    //println("wall speed "+(impulse/100));
    wallSound.cue(0);
    wallSound.speed(impulse / 100);// 
    wallSound.play();
  }
  if (b1 == glob || b2 == glob) { // b1 or b2 are the glob
    // glob sound
    println("droid "+(impulse/10));
    globSound.cue(0);
    globSound.speed(impulse / 10);
    globSound.play();
  }
   for (int i=0;i<jamGlobs.length;i++){
     if (b1 == jamGlobs[i] || b2 == jamGlobs[i]){// its a crate
         jamSounds[i].cue(0);
         jamSounds[i].speed(0.5 + (impulse / 10000));// 10000 as the jamGlobs move slower??
         jamSounds[i].play();
     }
   }
  //
}

