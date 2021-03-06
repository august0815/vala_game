/*
Data structures used by Vala Racer
*/
//using Gee;

public class GameState : GLib.Object {
	public int xRes;
	public int yRes;
	public int bpp;
	public bool running = true;
	public int roadSegLength = 50;

	public GameState ( int inXRes, int inYRes, int inBpp ) {
		xRes = inXRes;
		yRes = inYRes;
		inBpp = bpp;
	}
}
/*
public class ObjectLibrary : GLib.Object {
	var object = new HashMap<string, int>;
   
	public ObjectLibrary () {
		object.set ( "tree", 200 );
	}
}
*/
public class ChunckOfObjects : GLib.Object {
	public int[] type;
	public int[] trackID;
	public int[] prcFromRoad;

	public ChunckOfObjects ( int nIndex ) {
		type = new int[nIndex];
		trackID = new int[nIndex];
		prcFromRoad = new int[nIndex];
	}
}

public class GeneratedObjects : GLib.Object {
	public List<int> type;
	public List<int> trackID;
	public List<int> prcFromRoad;
}

public class FrameData : GLib.Object {
	public double[] trackLeftX;
	public double[] trackRightX;
	public double[] trackLeftY;
	public double[] trackRightY;
	public bool[] divider;
	public int16[] groundColor;

	public FrameData ( int nIndex ) {
		trackLeftX = new double[nIndex];
		trackRightX = new double[nIndex];
		trackLeftY = new double[nIndex];
		trackRightY = new double[nIndex];
		divider = new bool[nIndex];
		groundColor = new int16[nIndex];
	}
}