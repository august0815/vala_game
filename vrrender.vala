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

		format = screen.format;
		flags = screen.flags;
		surfaceCache = new SurfaceCache ( format, flags );
		surfaceCache.build_cache ();
 	}

	public void sprite ( int type, double posX, double posY, double prcShrink ) {
		int iCache = (int) Math.floor( surfaceCache.nCaches * prcShrink );

		Rect placement = Rect();
		placement.x = (int16) ( posX - surfaceCache.surfaces[type, iCache].w / 2d);
		placement.y = (int16) ( posY - surfaceCache.surfaces[type, iCache].h );

		surfaceCache.surfaces[type, iCache].blit( null, screen, placement );
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
	private int iShoulder;
	private int16[] yValuesRoad;
	private int16[] xValuesRoad;

	public DrawWorld ( int winX, int winY ) {	
		winXSize = winX;
		winYSize = winY;
	}

	public void get_frame ( FrameData inFrame, ChunckOfObjects inObjs, ref Painter paint ) {
		frame = inFrame;
		objs = inObjs;

		paint.trapezoid ( {0, 0, 800, 800}, {500, 0, 0, 500}, {200, 200, 200});
		iSeg = (int) frame.trackLeftY.length - 1;
		iShoulder = objs.trackID.length - 1;

		while ( iSeg != 0 ) {
			iSeg -= 1;
			
			/*Since most everything is based on the position of the road segment
			  those values are added so that all methods can reach them
			*/
			yValuesRoad = { (int16) frame.trackLeftY[iSeg + 1], //bottom y
							(int16) frame.trackLeftY[iSeg], //top y 
							(int16) frame.trackRightY[iSeg], //bottom y
							(int16) frame.trackRightY[iSeg + 1] }; //top y 

			xValuesRoad = { (int16) frame.trackLeftX[iSeg + 1], //bottom left x
							(int16) frame.trackLeftX[iSeg], // top left x
							(int16) frame.trackRightX[iSeg],//bottom right x
							(int16) frame.trackRightX[iSeg + 1] }; // top right x

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
		double curRoadSize = xValuesRoad[2] - xValuesRoad[1];
		double nextRoadSize = xValuesRoad[3] - xValuesRoad[0];
		double roadOfDivPrc = ( 100 - 1 ) / 200d;
		int16 curDivSize = (int16) ( curRoadSize * roadOfDivPrc );
		int16 nextDivSize = (int16) ( nextRoadSize * roadOfDivPrc );
		uchar[] RGB = { 50, 50, 50 };
		
		if ( frame.divider[iSeg] == true ){
			int16[] yValues = yValuesRoad;

			int16[] xValues = { xValuesRoad[0] + nextDivSize,
								xValuesRoad[1] + curDivSize,
								xValuesRoad[2] - curDivSize,
								xValuesRoad[3] - nextDivSize};
			paint.trapezoid ( xValues, yValues, RGB);
		}
	}

	public void prep_shoulder_obj ( ref Painter paint) {
		double curRoadSize = frame.trackRightX[iSeg] - frame.trackLeftX[iSeg];
		double prcShrink = (double)curRoadSize / (double)winXSize;
		
		while ( objs.trackID[iShoulder] == (iSeg) ) {
			int objType = objs.type[ iShoulder ];
			double objPrcOfRoad = objs.prcFromRoad[ iShoulder ] / 100d;
			double posOffset = curRoadSize * objPrcOfRoad;

			double objX;
			double objY;

			if ( objPrcOfRoad < 0 ) { //Obj on left side
				int spritePos = xValuesRoad[ 1 ] + (int)posOffset;
				objX = spritePos;
				objY = frame.trackLeftY[iSeg];
			}
			else {
				int spritePos = xValuesRoad[ 2 ] + (int)posOffset;
				objX = spritePos;
				objY = frame.trackLeftY[iSeg]; 
			}

			paint.sprite ( objType, objX , objY, prcShrink );
			
			iShoulder -= 1;
		}
	}
}

public class SurfaceCache : GLib.Object {
	public SDL.Surface[,] surfaces;
	public int nCaches = 600;
	private unowned SDL.PixelFormat format;
	private uint32 flags;

	public SurfaceCache ( SDL.PixelFormat inFormat, uint32 inFlags ) {
		format = inFormat;
		flags = inFlags;
	}

	public void build_cache () {
		try {
			var directory = File.new_for_path ("./images");
			var enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
		
			FileInfo fileInfo;
			int i = 0;
			while ((fileInfo = enumerator.next_file (null)) != null) {
				i += 1;
			}
			
			surfaces = new SDL.Surface[i, nCaches];
			//Reset enumerator
			enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0, null);

			i = 0;
			while (( fileInfo = enumerator.next_file (null)) != null ) {
				process_image (i, fileInfo.get_name () );
				i += 0;
			}
		}
		catch (GLib.Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
	}

	private void process_image (int cacheIndex, string file) {
		SDL.Surface image = SDLImage.load( "images/" + file );

		for ( int i = 0; i < this.nCaches; i++ ) {
			surfaces[cacheIndex, i] = SDLGraphics.RotoZoom.rotozoom( image, 0, ( i + 1d ) / this.nCaches, 0 );
			surfaces[cacheIndex, i] = surfaces[cacheIndex, i].convert( format, flags);

			//If any dimension is 0 it won't be drawn which would look weird
			if ( surfaces[cacheIndex, i].h == 0 || surfaces[cacheIndex, i].w == 0 ) {
				surfaces[cacheIndex, i] = surfaces[cacheIndex, i - 1].convert( format, flags);
			}
			//Transparency
			this.surfaces[cacheIndex, i].set_colorkey( SurfaceFlag.SRCCOLORKEY | SurfaceFlag.RLEACCEL, 16777215 );
		}
	}
}