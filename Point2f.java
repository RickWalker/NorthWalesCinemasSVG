import processing.core.PApplet;

public class Point2f {

  public float x;
  public float y;

  public Point2f(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  public boolean equals(Point2f a){
    return (x == a.x && y == a.y);
  }
  
  public float absDist(Point2f a){
    return (float) Math.sqrt( (y - a.y) * (y - a.y) + (x - a.x) * (x - a.x));
  }

  public String toString() {
    return "(" + PApplet.nf(x,1,3) + ", " + PApplet.nf(y,1,3) + ")";
  }

}


