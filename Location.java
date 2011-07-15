import processing.core.PApplet;

public class Location {

  public float lat;
  public float lon;

  public Location(float lat, float lon) {
    this.lat = lat;
    this.lon = lon;
  }

  public String toString() {
    return "(" + PApplet.nf(lat,1,3) + ", " + PApplet.nf(lon,1,3) + ")";
  }

}


