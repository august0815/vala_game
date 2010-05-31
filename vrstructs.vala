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
	public int16[] trackLeftX;
	public int16[] trackRightX;
	public int16[] trackLeftY;
	public int16[] trackRightY;
	public int16[] centDivLX;
	public int16[] centDivRX;
	public int16[] groundColor;

	public FrameData ( int nIndex ) {
		trackLeftX = new int16[nIndex];
		trackRightX = new int16[nIndex];
		trackLeftY = new int16[nIndex];
		trackRightY = new int16[nIndex];
		centDivLX = new int16[nIndex];
		centDivRX = new int16[nIndex];
		groundColor = new int16[nIndex];
	}
}