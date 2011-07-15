//import processing.opengl.*;
import geomerative.*;
import java.util.ArrayList; 

//Rick Walker 1/2010
//uses the Modest Maps Processing example and overlays
//cinema location data (as provided by Amy Chambers) onto it.
//then uses the SPH weighted averaging technique to colour areas 
//on the map appropriately.

//change 2/2/2010: move to using an svg map
//linear projection, and coords are:
//    * N: 53.5° N
//    * S: 51.3° N
//    * W: 5.5° W so -5.5 in my scheme
//    * E: 2.5° W so -2.5 in my scheme
// 
// Only uses Point2f and Location from modestmaps now

//color maps!

color [] purpleRedColours = {
  color(241, 238, 246),
  color(212, 185, 218),
  color( 201, 148, 199),
  color( 223, 101, 176),
  color( 231, 41, 138),
  color( 206, 18, 86),
  color(145, 0, 63) 
  };
  
  color [] tealColours = {
  color(246, 239, 247),
  color(208, 209, 230),
  color(166, 189, 219),
  color(103, 169, 207),
  color(54, 144, 192),
  color(2, 129, 138),
  color(1, 100, 80) 
  };

color [] earthyColours = {
  color(255, 255, 229), 
  color(255, 247, 188), 
  color(254, 227, 145),
  color(254, 196, 79), 
  color(254, 153, 41), 
  color(236, 112, 20), 
  color(204, 76, 2), 
  color(153, 52, 4), 
  color(102, 37, 6)
  }; 

color [] redColours = {
  //color(255, 255, 204),
  //color(255, 237, 160), 
  color(254, 217, 118),
  color(254, 178, 76),
  color(253, 141, 60),
  color(252, 78, 42),
  color(227, 26, 28),
  color(189, 0, 38),
  color(128, 0, 38)
  };

  RShape mapShape;
  RShape originalShape;
ArrayList contourPoints = new ArrayList(); //an arraylist of contourPoints objects
//extent of map
static float minY = 51.3;
static float maxY = 53.5;
static float minX = -5.5;
static float maxX = -2.5;

static float mapRatio = 523/626.0; //height is 1.63 x widt
float realHeight;//1252.0;
//static float realWidth = 1026.0;


// buttons take x,y and width,height:
ZoomButton out = new ZoomButton(5,5,14,14,false);
ZoomButton in = new ZoomButton(22,5,14,14,true);
PanButton up = new PanButton(14,25,14,14,UP);
PanButton down = new PanButton(14,57,14,14,DOWN);
PanButton left = new PanButton(5,41,14,14,LEFT);
PanButton right = new PanButton(22,41,14,14,RIGHT);

Location [] cinemaLocations;
float [] masses;
boolean updateNeeded;
float [] xpos; 
float [] ypos; 
String [] cinemaNames;
int closest;

int contourLevels=7; //how many divisions we want for contours - currently 5

float max_intensity;
static int gridres = 250;

// all the buttons in one place, for looping:
Button[] buttons = { 
  in, out, up, down, left, right };

//zoom
Integrator zoomDepth = new Integrator(1.0);
Integrator xOffset = new Integrator(0.0);
Integrator yOffset = new Integrator(0.0);
PFont font;

int prevMouseX, prevMouseY;

boolean gui = true;

void setup() {
  size(800, 400, JAVA2D);

  //mapImage = loadImage("Wales_location_map_small.png");

  realHeight = width*mapRatio;

  smooth();
  frameRate(20);
  RG.init(this);

  originalShape = RG.loadShape("fetch.svg");
  RG.setPolygonizer(RG.UNIFORMLENGTH);
  RG.setPolygonizerLength(8.0);
  mapShape = RG.polygonize(originalShape);
  //mapShape = originalShape;
  loadData();
  createSurface(width, (int) realHeight);
  updateNeeded = true;

  // set a default font for labels
  font = createFont("Verdana-Bold", 8);

  // enable the mouse wheel, for zooming
  addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
    }
  }
  ); 

}

void loadData(){
  String [] lines = loadStrings("cinemalist.txt");
  int cinema_count = lines.length/4;
  println("Found "+cinema_count+ " cinemas");
  cinemaLocations = new Location[cinema_count];
  masses = new float[cinema_count];
  xpos = new float[cinemaLocations.length];
  ypos = new float[cinemaLocations.length];
  cinemaNames = new String[cinema_count];
  cinema_count--;
  for(int i = 0;i<lines.length;i+=4){
    //parse line into two tokens
    cinemaNames[cinema_count] = lines[i];
    String [] latlon = splitTokens(lines[i+2],",");
    masses[cinema_count] = 100.0;//float(lines[i+3]);
    cinemaLocations[cinema_count--]=new Location(float(latlon[0]), float(latlon[1]));
  }
}

void updateAnimation(){
  zoomDepth.update();
  xOffset.update();
  yOffset.update();
  //println("Box is " + zoomX1.value +", " + zoomY1.value + " to " + zoomX2.value +", "+ zoomY2.value);
}

boolean needsLoop(){
  //if all the integrators are done, then stop the redraw
  boolean result =  (zoomDepth.accel != 0.0);
  //println("ZoomDepth result is " + result);

  result = result && (xOffset.accel != 0.0 );
  //println("xOffset result is " + (xOffset.accel != 0.0));

  result = result && (yOffset.accel != 0.0 );
  //println("yOffset result is " + (yOffset.accel != 0.0));

  //println("Final result is " + result);
  return result;
}

void draw() {
  updateAnimation();

  background(0);
  // draw the map:

  RG.shape(mapShape, xOffset.value, yOffset.value, width * zoomDepth.value,  realHeight * zoomDepth.value);

  // (that's it! really... everything else is interactions now)

  smooth();

  // see if the arrow keys or +/- keys are pressed:
  // (also check space and z, to reset or round zoom levels)
  if (keyPressed) {
    if (key == CODED) {
      if (keyCode == LEFT) {
        panLeft();
      }
      else if (keyCode == RIGHT) {
        panRight();
      }
      else if (keyCode == UP) {
        panUp();
      }
      else if (keyCode == DOWN) {
        panDown();
      }
    }  
    else if (key == '+' || key == '=') {
      zoomIn();
    }
    else if (key == '_' || key == '-') {
      zoomOut();
    }
    loop();
  }

  drawOverlay();
  drawWater();//to cut at edges
  drawCinemas();
  drawButtons();

  checkForMouseOver();

  if (gui) {
    drawMapInformation();


    //this is exactly the same as SPH calculation - 
    //apply the same optimisation stuff that SPLASH uses and I used in my C++ code
    //so: work per location instead of pixel!
    //still need big loop to draw I guess?
    //updateNeeded = false;
  }  
  if (!needsLoop()){
    //repolygonize map!
    //RG.setPolygonizerLength(max(1.0, 10/zoomDepth.value));
    //println("Zoom is " + zoomDepth.value);
    //mapShape = RG.polygonize(originalShape);
    // println("NoLoop!");
    noLoop();// stop after this run
  }
}

void drawWater(){
  RShape water = mapShape.getChild("path45");
  water.setStroke(0);
  //water.setStrokeWeight(1);
  //RG.setStrokeWeight(2);
  RG.shape(water, xOffset.value, yOffset.value, width * zoomDepth.value,  realHeight * zoomDepth.value);
}

void drawCinemas(){
  colorMode(RGB, 255);
  ellipseMode(CENTER);
  for(int i = 0 ; i < cinemaLocations.length ; i++){
    Point2f p = locationPoint(cinemaLocations[i]);
    stroke(0);
    fill(0, 0, 0);
    ellipse(p.x, p.y, 2*zoomDepth.value, 2*zoomDepth.value);
  }

}

void drawButtons(){
  // draw all the buttons and check for mouse-over
  boolean hand = false;
  if (gui) {
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].draw();
      hand = hand || buttons[i].mouseOver();
    }
  }

  // if we're over a button, use the finger pointer
  // otherwise use the cross
  // (I wish Java had the open/closed hand for "move" cursors)
  cursor(hand ? HAND : CROSS);
}

void drawCentrePoint(){
  //cheat and draw centre point
  Point2f p = locationPoint(new Location(52.4, -4.0));
  fill(255, 255, 0);
  ellipse(p.x, p.y, 5, 5);
}

void drawMapInformation(){
  textFont(font, 12);

  // grab the lat/lon location under the mouse point:
  Location location = pointLocation(mouseX, mouseY);

  // draw the mouse location, bottom left:
  fill(0);
  noStroke();
  rect(5, height-5-g.textSize, textWidth("mouse: " + location), g.textSize+textDescent());
  fill(255,255,0);
  textAlign(LEFT, BOTTOM);
  text("mouse: " + location, 5, height-5);

  // grab the center
  location = pointLocation(width/2, height/2);

  // draw the center location, bottom right:
  fill(0);
  noStroke();
  float rw = textWidth("map: " + location);
  rect(width-5-rw, height-5-g.textSize, rw, g.textSize+textDescent());
  fill(255,255,0);
  textAlign(RIGHT, BOTTOM);
  text("map: " + location, width-5, height-5);
}

void drawOverlay(){
  if(gui){
    noStroke();
  }
  else{
    stroke(0);
  }
  ContourPoints c;
  for(int level = 0; level < 5; level++){
    for(int j = 0 ; j < contourPoints.size(); j++){

      c = (ContourPoints) contourPoints.get(j);
      if(c.level == level){
        Point2f t;
        float colorval = c.value; //first value is for colour!
        float trans;
        if(colorval==0.0){
          trans = 0;
        }
        else{
          trans = 200;
        }
        //color a = getRedColour((int) map(colorval, 0, max_intensity, 0, redColours.length-1));
        //color a = getEarthyColour((int) map(colorval, 0, max_intensity, 0, earthyColours.length-1));
        //color a = getPurpleRedColour((int) map(colorval, 0, max_intensity, 0, purpleRedColours.length-1));
        color a = getMapColor(colorval, tealColours);
        a = color(red(a), green(a), blue(a), trans);
        fill(a);
        beginShape();
        for(int i = 0; i< c.points.size(); i++){
          t = (Point2f) c.points.get(i);
          vertex(xOffset.value + zoomDepth.value * t.x, yOffset.value + zoomDepth.value * t.y);
        }
        endShape(CLOSE);
      }
    }
  }
}

color getMapColor(float cv, color [] cs){
  int a = (int) map(cv, 0, max_intensity, 0, cs.length-1);
  a = constrain(a, 0, cs.length-1);
  return cs[a];
}

Point2f localToWorld(int px, int py){
  //converts from coords relative to the window to coords relative to the zoomed space
  return new Point2f((px - xOffset.value)/(zoomDepth.value * width) , (py - yOffset.value)/(zoomDepth.value * height));
}

Point2f localToWorldTarget(int px, int py){
  return new Point2f((px - xOffset.value)/(zoomDepth.target * width) , (py - yOffset.value)/(zoomDepth.target * height));
}


Point2f locationPoint(Location a){
  //converts this Location to a pixel position
  Point2f b = new Point2f( map(a.lon, maxX, minX, xOffset.value + zoomDepth.value*width, xOffset.value), 
  map(a.lat, minY, maxY,  yOffset.value + zoomDepth.value * realHeight, yOffset.value) );
  return b;
}

Point2f locationPointTarget(Location a){
  //converts this Location to a pixel position
  Point2f b = new Point2f( map(a.lon, maxX, minX, xOffset.value + zoomDepth.target*width, xOffset.value), 
  map(a.lat, minY, maxY,  yOffset.value + zoomDepth.target * realHeight, yOffset.value) );
  return b;
}

Location pointLocation(int px, int py){
  //converts this point to a location
  Location a = new Location(map(py, yOffset.value, yOffset.value + zoomDepth.value * height, maxY, minY), 
  map(px, xOffset.value, xOffset.value + zoomDepth.value*width, minX, maxX));
  return a;
}

Location pointLocationTarget(int px, int py){
  //converts this point to a location
  Location a = new Location(map(py, yOffset.value, yOffset.value + zoomDepth.target * height, maxY, minY), 
  map(px, xOffset.value, xOffset.value + zoomDepth.target*width, minX, maxX));
  return a;
}

void createSurface(int w, int ht){
  //clear old surface
  float [] overlay = new float[gridres*gridres];

  Location zerozero =  new Location(map(0, 0, ht, maxY, minY), 
  map(0, 0, w, minX, maxX));
  Location widthheight =  new Location(map(ht, 0,  ht, maxY, minY), 
  map(w, 0, w, minX, maxX));
  float boxsize_x, boxsize_y;
  boxsize_x = distanceBetween(zerozero, new Location(zerozero.lat, widthheight.lon));
  boxsize_y = distanceBetween(zerozero, new Location(widthheight.lat, zerozero.lon));

  for(int i = 0; i < cinemaLocations.length; i++){
    ypos[i] = distanceBetween(zerozero, new Location(cinemaLocations[i].lat, zerozero.lon));
    if(cinemaLocations[i].lat > zerozero.lat)
      ypos[i] *= -1;

    xpos[i] = distanceBetween(zerozero, new Location(zerozero.lat, cinemaLocations[i].lon)); //need signed distance!
    if(cinemaLocations[i].lon < zerozero.lon)
      xpos[i] *= -1;
  }

  max_intensity = Float.MIN_VALUE;
  //creates the surface
  double cinema_density = 100000.0;
  //double cinema_mass=100.0;
  double r_cloud = boxsize_x;
  double r_cloud_y = boxsize_y;
  double h = 5.0;// r_cloud / 20.0; //smoothing length
  double twoh = 2 * h;//2*smoothing length (kernel radius)
  double hi1 = 1.0/h; // 1/hi
  double hi21 = hi1 * hi1; //1/h^2
  int npixx = gridres - 1;
  int npixy = gridres - 1;
  double xmin = 0;
  double ymin = 0;

  double pixwidth = r_cloud / (float) npixx;
  double pixheight = r_cloud_y / (float) npixy;

  double ypix;
  int ipix, jpix, ipixmin, ipixmax, jpixmin, jpixmax;
  double dy, dy2;
  double [] dx2i=new double[npixx+1];
  double qq,qq2,wab;
  double w_j;
  double termnorm, term;

  for(int i = 0 ; i < cinemaLocations.length ; i++){
    //ipixmin is the minimum x value that this cinema affects
    //so need to find the coordinates of the point twoh miles west of it, then take xmin from that?

    //ipixmin = (int) ((cinemaLocations[i].lat - twoh - xmin) / pixwidth_i);
    ipixmin = (int) ((xpos[i] - twoh) / pixwidth);
    jpixmin = (int) ((ypos[i] - twoh) / pixheight);
    ipixmax = (int) ((xpos[i] + twoh) / pixwidth) + 1;
    jpixmax = (int) ((ypos[i] + twoh) / pixheight) + 1;

    if (ipixmin<0) ipixmin = 0;
    if (jpixmin<0) jpixmin = 0;
    if (ipixmax>npixx) ipixmax = npixx;
    if (jpixmax>npixy) jpixmax = npixy;

    for(ipix=ipixmin;ipix<=ipixmax;ipix++){
      dx2i[ipix]=(((ipix-0.5)*pixwidth - xpos[i]) * ( (ipix-0.5) * pixwidth - xpos[i]))*hi21; // + dz2;
    }

    //assume total'mass' 100 and each 'density' is 50
    //eventually, mass = , density = showings per day per screen
    w_j = (masses[i] / cinemaLocations.length)/(hi1 * hi21);
    termnorm = 10./(7.*PI)*w_j;
    term = termnorm;

    for (jpix=jpixmin;jpix<=jpixmax;jpix++){
      ypix=ymin+(jpix-0.5)*pixheight;
      dy=ypix-ypos[i];
      dy2=dy*dy*hi21;
      for(ipix=ipixmin;ipix<=ipixmax;ipix++){
        qq2=dx2i[ipix] + dy2;
        //SPH Cubic spline
        //if in range
        if(qq2<4.0){
          qq=Math.sqrt(qq2);
          if(qq<1.0){
            wab=(1.-1.5*qq2 + 0.75*qq*qq2);
          }
          else{ 
            wab=0.25*(2.-qq)*(2.-qq)*(2.-qq);
          }						
          overlay[jpix*gridres + ipix]+= term*wab;
          max_intensity = max(overlay[jpix*gridres + ipix], max_intensity);
        }
      }
    }
  }
  double zmin = 0;
  double zmax = max_intensity;

  double [] contours = new double[contourLevels] ;
  for(int i = 0; i < contourLevels; i++){
    contours[i] = map(i+1, 0, contourLevels, 0, max_intensity);
  }
  //now that we have the grid, generate contours!
  //mangle array back into 2D
  double [][] values = new double[gridres][gridres];
  for(int x = 0 ; x< gridres; x++){
    for(int y = 0; y<gridres; y++){
      values[x][y] =overlay[y*gridres+x];
    }
  } 

  double [] xaxis = new double[gridres];
  double [] yaxis = new double[gridres];
  boxsize_x = w/(float) gridres;
  boxsize_y = ht/(float) gridres;
  for(int i=0;i<gridres;i++){
    xaxis[i]=i*boxsize_x;
    yaxis[i]=i*boxsize_y;
  }
  Conrec temp = new Conrec();
  noFill();
  stroke(0);
  ArrayList lines; //one per contour set
  lines = temp.contour(values, 0, gridres-1, 0, gridres-1, xaxis, yaxis, 5, contours );
  //so actually, lines should contain 5 objects
  println("Lines has " + lines.size() + " objects");
  ContourPoints toSplit;
  for(int i = 0; i < lines.size(); i++){
    toSplit = (ContourPoints) lines.get(i);
    //contourShape = new PShape();
    while( toSplit.points.size() !=0) {
      ContourPoints mytry = splitToPaths(toSplit);
      //mytry.setStroke(0);
      contourPoints.add(mytry); //add to main arraylist of contourpoints
      //contourShape.addPath(mytry);
    }
  }

}

Point2f findNextPoint(Point2f a, ArrayList b){
  Point2f c, d;
  for(int i = 0; i < b.size()-1; i+=2){ //go up in twos!
    c = (Point2f) b.get(i);
    d = (Point2f) b.get(i+1);
    if(c.equals(a)){
      b.remove(i+1); //remove highest index first!
      b.remove(i);
      return d;
    }
    else if (d.equals(a)){
      b.remove(i+1);
      b.remove(i);
      return c;
    }
  }
  return null;
}

ContourPoints splitToPaths(ContourPoints p){
  //returns a list of points!
  //takes a ContourPoints object containing many paths
  //extracts one path from it
  //and returns it as a ContourPoints object
  ContourPoints toReturn = new ContourPoints(p.level, p.value);

  //put first line segment in
  Point2f a = (Point2f) p.points.get(0);
  toReturn.add(a);
  p.points.remove(0);
  a = (Point2f) p.points.get(0);
  toReturn.add(a);
  p.points.remove(0);

  Point2f b;
  while((b = findNextPoint(a, p.points)) !=null){
    toReturn.add(b);
    //now want b to become the starting point
    a = b;
  };
  return toReturn;
}


float distanceBetween(Location l1, Location l2){
  //proper haversine formula!
  float lat1 = radians(l1.lat);
  float lat2 = radians(l2.lat);
  float lon1 = radians(l1.lon);
  float lon2 = radians(l2.lon);
  //r is radius of earth
  int r = 3959;
  float dlat = lat2 - lat1;
  float dlon = lon2 - lon1;
  //float a = (sin(dlat/2.0))^2 + cos(l1.lat) * cos(l2.lat) * (sin(dlon/2.0))^2;
  float a = (sin(dlat/2.0)*sin(dlat/2.0)) + cos(lat1) * cos(lat2) * (sin(dlon/2.0))* (sin(dlon/2.0));
  float c = 2 * atan2(sqrt(a), sqrt(1-a)) ;
  float  d = r * c;
  return d;
}

void keyReleased() {
  if (key == 'g' || key == 'G') {
    gui = !gui;
    loop();
  }
  else if (key == 's' || key == 'S') {
    save("svg-maps-app.png");
  }
}

void mouseMoved(){
  //check for mouseover events
  //convert each location to pixel position
  //find the one closest to the mouse
  // print it
  updatePreviousMouse();
  //loop();
  closest = -1;
  for (int i = 0 ; i < cinemaLocations.length; i++){
    Point2f actual = locationPoint(cinemaLocations[i]);
    if( abs( actual.x - mouseX ) < 5){
      if( abs(actual.y - mouseY ) < 5){
        closest = i;
        loop();//restart draw loop!
      }
    }
  }
}

void checkForMouseOver(){
  mouseMoved(); //to make sure we're current
  if (closest != -1){
    //println("Closest to..." + closest);
    Point2f p = locationPoint(cinemaLocations[closest]);
    fill(255, 0, 0);
    ellipse(p.x, p.y, 4*zoomDepth.value, 4*zoomDepth.value);
    //label time!
    stroke(0);
    fill(1, 108, 89);
    textFont(font, 12);
    textAlign(LEFT, BOTTOM);

    //split lines on commas
    String [] eachLine = splitTokens(cinemaNames[closest], ",");

    float w = textWidth(trim(eachLine[0]));
    float h = textAscent() + textDescent();

    int xpos = mouseX + (int) (5*zoomDepth.value);
    if (w + mouseX > width){
      //do it to the right instead of to the left
      xpos -= w;
    }

    for(int i = 0; i < eachLine.length; i++){
      text(trim(eachLine[i]), xpos, mouseY + i*h - h*(eachLine.length-1));//*zoomDepth.value);
    }
  }
}


// see if we're over any buttons, otherwise tell the map to drag
void mouseDragged() {

  updateNeeded = true;
  boolean hand = false;
  if (gui) {
    for (int i = 0; i < buttons.length; i++) {
      hand = hand || buttons[i].mouseOver();
      if (hand) break;
    }
  }
  if (!hand) {
    xOffset.value = xOffset.target + mouseX - prevMouseX;
    xOffset.target(xOffset.target + mouseX - prevMouseX);
    yOffset.value =  yOffset.target + mouseY - prevMouseY;
    yOffset.target(yOffset.target + mouseY - prevMouseY);
  }
  updatePreviousMouse();
  loop();//need to re-draw *something*
}

// zoom in or out:
void mouseWheel(int delta) {

  if (delta > 0) {
    zoomOut();
  }
  else if (delta < 0) {
    zoomIn();
  }
  //updatePreviousMouse();
  loop();

}

// see if we're over any buttons, and respond accordingly:
void mouseClicked() {
  if (in.mouseOver()) {
    zoomIn();
  }
  else if (out.mouseOver()) {
    zoomOut();
  }
  else if (up.mouseOver()) {
    panUp();
  }
  else if (down.mouseOver()) {
    panDown();
  }
  else if (left.mouseOver()) {
    panLeft();
  }
  else if (right.mouseOver()) {
    panRight();
  }
  //updatePreviousMouse();
  loop();
}

void updatePreviousMouse(){
  //can't rely on previous frame any more, so cheat!
  prevMouseX = mouseX;
  prevMouseY = mouseY;
}

void zoomIn(){
  zoomDepth.target(zoomDepth.value * 1.2);
  //change the offset so that the same lat/lon is in the centre
  adjustCentre();
}

void zoomOut(){
  zoomDepth.target(zoomDepth.value * (1.0/1.2));
  adjustCentre();
}

void adjustCentre(){
  Point2f oldCentre = localToWorld(width/2, height/2);
  Point2f newCentre = localToWorldTarget(width/2, height/2);
  xOffset.target(xOffset.value - (oldCentre.x-newCentre.x) * width * zoomDepth.target);
  yOffset.target(yOffset.value - (oldCentre.y-newCentre.y) * height * zoomDepth.target);
}

void panUp(){
  yOffset.target(yOffset.value + 50);
}

void panDown(){
  yOffset.target(yOffset.value - 50);
}

void panLeft(){
  xOffset.target(xOffset.value + 50);
}

void panRight(){
  xOffset.target(xOffset.value - 50);
}
























































