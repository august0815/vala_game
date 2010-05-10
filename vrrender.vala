using SDL;
using SDLGraphics;
using SDLImage;

public class Painter : GLib.Object {
	private unowned SDL.Surface screen;
	private unowned PixelFormat format;
	private uint32 flags;
	SurfaceCache surfaceCache;

	public Painter ( int xRes, int yRes ) {

		uint32 video_flags = SurfaceFlag.DOUBLEBUF | SurfaceFlag.HWACCEL | SurfaceFlag.HWSURFACE;
        SDL.init (InitFlag.VIDEO);
        screen = Screen.set_video_mode ( xRes, yRes, 32, video_flags);

        if (screen == null) {
            stderr.printf ("Could not set video mode.\n");
        }
		SDL.WindowManager.set_caption ("Vala Racer", "");

//		SDL.WindowManager.toggle_fullscreen (screen);

		format = screen.format;
		flags = screen.flags;
		surfaceCache = new SurfaceCache (format, flags );
		surfaceCache.trees ();

 	}

	public void sprite ( int type, int16 posX, int16 posY, double prcShrink ) {

		int iCache = (int) ( surfaceCache.nCaches * prcShrink );

		Rect placement = Rect();
		placement.x = posX - (int16) surfaceCache.tree[iCache].w / 2;
		placement.y = posY - (int16) surfaceCache.tree[iCache].h;


		surfaceCache.tree[iCache].blit( null, screen, placement );
	}

	public void trapezoid ( int16[] xValues, int16[] yValues, uchar[] RGB ) {
		Polygon.fill_rgba ( screen, xValues, yValues, 4, RGB[0], RGB[1], RGB[2], 255);
	}

	public void flip () {
		screen.flip ();
	}

	public void lockit () {
		screen.do_lock();
	}

	public void unlockit () {
		screen.unlock();
	}
}

public class DrawWorld : GLib.Object {
	private FrameData frame;
	private ChunckOfObjects objs;
	private int winXSize;
	private int winYSize;
	private int iSeg;
	private int iLines;
	private int16[] yValuesRoad;
	private int16[] xValuesRoad;

	public DrawWorld ( FrameData inFrame, ChunckOfObjects inObjs, int winX, int winY ) {	
		frame = inFrame;
		objs = inObjs;
		winXSize = winX;
		winYSize = winY;

		iLines = (int) frame.trackLeftY.length - 1;
	}

	public void get_frame ( ref Painter paint ) {
		paint.trapezoid ( {0, 0,800,800}, {500, 0,0, 500}, {200,200,200});
		for (int i = 0; i < iLines; i++){
			iSeg = iLines - i;
			
			/*Since most everything is based on the position of the road segment
			  those values are added so that all methods can reach them
			*/
			yValuesRoad = { frame.trackLeftY[iSeg - 1], //bottom y
							frame.trackLeftY[iSeg], //top y 
							frame.trackRightY[iSeg], //bottom y
							frame.trackRightY[iSeg - 1] }; //top y 

			xValuesRoad = { frame.trackLeftX[iSeg - 1], //bottom left x
							frame.trackLeftX[iSeg], // top left x
							frame.trackRightX[iSeg],//bottom right x
							frame.trackRightX[iSeg - 1] }; // top right x

			paint.lockit();
			draw_grass( ref paint );
			draw_road( ref paint );
			draw_divider( ref paint );
			paint.unlockit();

			prep_shoulder_obj( ref paint );

		}
	}

 	public void draw_road ( ref Painter paint) {
		uchar[] RGB = { 0xFF, 0x00, 0x0F };

		paint.trapezoid ( xValuesRoad, yValuesRoad, RGB);
	}

	public void draw_grass ( ref Painter paint) {
		uchar[] RGB = { 10, 10, 10 };
		if ( frame.groundColor[iSeg] == 1 ) {
			RGB = { 30, 30, 30 };
		}

		int16[] yValues = { yValuesRoad[0], yValuesRoad[1], yValuesRoad[1], yValuesRoad[0] };
			
		int16[] xValues = { 0, //bottom left x
						0 , // top left x
						xValuesRoad[1],//bottom right x
						xValuesRoad[0] }; // top right x
		paint.trapezoid ( xValues, yValues, RGB);


		yValues = { yValuesRoad[3], yValuesRoad[2], yValuesRoad[2], yValuesRoad[3] };

		xValues = { xValuesRoad[3], //bottom left x
					xValuesRoad[2],
					(int16) winXSize,//bottom right x
					(int16) winXSize };// right x
		paint.trapezoid ( xValues, yValues, RGB);
	}

	public void draw_divider ( ref Painter paint ) {
		uchar[] RGB = { 50, 50, 50 };
		int topDiv = frame.centDivLX[iSeg];
		int botDiv = frame.centDivLX[iSeg - 1];

		if ( topDiv != 0 && botDiv != 0){
			int16[] yValues = yValuesRoad;

			int16[] xValues = { frame.centDivLX[iSeg - 1],
								frame.centDivLX[iSeg ],
								frame.centDivRX[iSeg],
								frame.centDivRX[iSeg - 1] };
			paint.trapezoid ( xValues, yValues, RGB);
		}
	}

	public void prep_shoulder_obj ( ref Painter paint ) {
		int curRoadSize = xValuesRoad[2] - xValuesRoad[1];
		double prcShrink = (double)curRoadSize / (double)winXSize;

		int test = objs.trackID[iSeg];

		int last;
		if ( iSeg != iLines ) { 
			last = objs.trackID[iSeg + 1];
		}
		else {
			last = test + 1;//(int) objs.trackID.length() - 1;
		}

		test = 1;
		while ( test == 1 ) {

			int objType = objs.type[ iSeg ];
			double objPrcOfRoad = Math.floor((double)objs.prcFromRoad[ iSeg ] / 100d);

			int16 objX;
			int16 objY;
			if ( objPrcOfRoad < 0 ) { //Obj on left side
				objX = (int16) ( xValuesRoad[ 1 ] + Math.ceil(objPrcOfRoad * curRoadSize));
				objY = yValuesRoad[1];
			}
			else {
				objX = (int16) ( xValuesRoad[ 2 ] + Math.floor(objPrcOfRoad * curRoadSize));
				objY = yValuesRoad[2]; 
			}

			paint.sprite ( objType, objX , objY, prcShrink );
			test = 0;
		}
	}
}

public class SurfaceCache : GLib.Object {
	public SDL.Surface[] tree;
	public int nCaches = 300;
	private unowned SDL.PixelFormat format;
	private uint32 flags;

	public SurfaceCache ( SDL.PixelFormat inFormat, uint32 inFlags ) {
		tree = new SDL.Surface[nCaches];
		format = inFormat;
		flags = inFlags;
	}

	public void trees () {
		SDL.Surface image = SDLImage.load( "/home/l/tree200.png" );

		for ( int i = 0; i < this.nCaches; i++ ) {
			this.tree[i] = SDLGraphics.RotoZoom.rotozoom( image, 0, ( i + 1f ) / this.nCaches, 0 );
			this.tree[i] = this.tree[i].convert( format, flags);
			this.tree[i].set_colorkey( SurfaceFlag.SRCCOLORKEY | SurfaceFlag.RLEACCEL, 16777215 );
		}
	}
}