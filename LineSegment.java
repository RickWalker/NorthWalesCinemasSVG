public class LineSegment{
  public Point2f start;
  public Point2f end;
  float value; //the value of the contour that this encloses
  
  LineSegment(Point2f start, Point2f end){
    this.start = start;
    this.end = end;
  }
  
    LineSegment(Point2f start, Point2f end, float v){
    this.start = start;
    this.end = end;
    this.value = v;
  }
  
  
  boolean equals(LineSegment a){
    return (start == a.start && end == a.end);
  }
}
