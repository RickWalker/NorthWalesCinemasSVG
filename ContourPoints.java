import java.util.ArrayList;

public class ContourPoints{
  public ArrayList points;
  public int level; //the level of contour: draw in order 0 upwards
  public float value;
  
  public ContourPoints(int level, float value){
    this.level = level;
    this.value = value;
    points = new ArrayList();
  }
  
  public void add(Point2f p){
    points.add(p);
  }
}
