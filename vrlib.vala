using SDL;

public class RoadProjector : GLib.Object {
	private const int TRACK_CHUNCK = 500;
	private const int ROAD_SEG_LENGTH = 50;
	private const int SCREEN_Y_OFFSET = 300;
	private int winXSize;
	private int winYSize;
	private int eyeX = 0; // eyes horizontal posistion from virtual screen.
	private int eyeY = 0;
	private int eyeZ = 100;

	public double xShift { get; set; default = 0; }
	public int trackStart { get; set; default = 0; }

	public RoadProjector ( int inX, int inY ) {
		winXSize = inX;
		winYSize = inY;
		eyeX += inX / 2;
		eyeY += inY / 2;
	}

	public FrameData build_road ( ref VRSql db ) {

		FrameData newFrame = new FrameData ( TRACK_CHUNCK );

		//Which road segment does trackStart belong to
	 	int iFirstSeg = (int) Math.round ( trackStart / ROAD_SEG_LENGTH ) + 1;

		bool roadExists = db.check_scope( iFirstSeg, iFirstSeg + TRACK_CHUNCK );
		if ( !roadExists ) { 
			RoadGenerator roadGen = new RoadGenerator ( 0, 0, 0, 0 );
			while ( !roadExists ) {
				roadGen.new_seg ( ref db );
				roadGen.new_delta ( 0, 0, 0, 0);
				roadExists = db.check_scope( iFirstSeg, iFirstSeg + TRACK_CHUNCK );			
			}
		}
		int[,] curTrack = db.get_road( iFirstSeg, iFirstSeg + TRACK_CHUNCK );

		//How many pixels untilfrom trackStart till the next road seg
		int relTrackStart = (iFirstSeg) * ROAD_SEG_LENGTH - trackStart;
		//How many procent away of ROAD_SEG_LENGTH the next seg is
		double dampeningPrc = (double) relTrackStart / ROAD_SEG_LENGTH;

		curTrack[0, 0] = (int) (curTrack[0, 0] * (dampeningPrc));
		curTrack[1, 0] = (int) (curTrack[1, 0] * (dampeningPrc));
		curTrack[2, 0] = (int) (curTrack[2, 0] * (dampeningPrc));

		int xOffset = 0;
		int yOffset = 0;
		int tiltOffset = 600;//(int) (curTrack[2, 0] * (1 - dampeningPrc));;
		int pointZ = eyeZ; //First seg is right underneath the screen
		for ( int i = 0; i < TRACK_CHUNCK; i++ ) { 
			double[] xPos;
			double[] yPos;

			if ( tiltOffset < 0 ) {
				xPos = new double[] { xOffset + xShift, (xOffset + winXSize) + xShift };
				yPos = new double[] { yOffset, yOffset };
			}
			else {
				int spill = (winXSize - tiltOffset) / 2;
				xPos = new double[] { xOffset + xShift, (xOffset + winXSize)+xShift };
				yPos = new double[] { yOffset, yOffset};
			}
			//vectors from point towards eye
   			double[] xVectors = new double[] { eyeX - xPos[0], eyeX - xPos[1] }; //Left and right
			double[] yVectors = new double[] { eyeY - yPos[0], eyeY - yPos[1] };
			double zVector = -pointZ;  

			//Magnitude of the vector from left and right point
			double vecMagL = (double)Math.sqrt( Math.pow(xVectors[0], 2) + Math.pow(yVectors[0], 2) + Math.pow(zVector, 2) );
			double vecMagR = (double)Math.sqrt( Math.pow(xVectors[1], 2) + Math.pow(yVectors[1], 2) + Math.pow(zVector, 2) );
										 
			//Normalized vectors
			double[] vecNormL = new double[] { xVectors[0] / vecMagL, yVectors[0] / vecMagL, zVector / vecMagL };
			double[] vecNormR = new double[] { xVectors[1] / vecMagR, yVectors[1] / vecMagR, zVector / vecMagR };
										 
			//pointZ is always bigger then eyeZ, z vector is negative
			double factorL = ( eyeZ - pointZ ) / vecNormL[2];
			double factorR = ( eyeZ - pointZ ) / vecNormR[2];

			//xOffset is the starting position for the vector + how much the vector
			//changes X before it hits the screen
			int16 projXL = (int16) ( (vecNormL[0] * factorL + xPos[0]));
			int16 projXR = (int16) ( (vecNormR[0] * factorR + xPos[1]));

			//winYSize because 0y is on top of the screen so the image needs to be inverted
			int16 projYL = (int16) ( winYSize - ( vecNormL[1] * factorL + yPos[0] ) );
			int16 projYR = (int16) ( winYSize - ( vecNormR[1] * factorR + yPos[1] ) );

			//Prepare next values
			xOffset += curTrack[0, i];
			yOffset += curTrack[1, i];
			tiltOffset = 600;//(int) ( curTrack[2, i] );
			pointZ = eyeZ + ROAD_SEG_LENGTH * i + (int) ( dampeningPrc * ROAD_SEG_LENGTH );

			newFrame.trackRightX[i] = projXR;
			newFrame.trackRightY[i] =  projYR;
			newFrame.trackLeftX[i] = projXL;
			newFrame.trackLeftY[i] = projYL;

			divider ( iFirstSeg , i, ref newFrame );
			ground ( iFirstSeg, i, ref newFrame );
		}
		return newFrame;
	}

	private void divider ( int db, int index, ref FrameData newFrame ) {
		int divWidthPrc = 1; //How many percent of the roads width is divider
		int divSegLength = 3; //Number of segments a divider should span
		int divSegSepr = 4; //Number of road segs should seperate each divider

		int trackIndex = db + index;
		float roadOfDivPrc = ( 100 - divWidthPrc ) / 200f;
			
		if ( trackIndex % ( divSegLength + divSegSepr ) > ( divSegLength ) ) {


			int roadLeftX = newFrame.trackLeftX[index];
			int roadRightX = newFrame.trackRightX[index];

			int roadWidth = ( roadLeftX - roadRightX ).abs ();
			float roadOfDiv = (roadWidth * roadOfDivPrc);

			newFrame.centDivLX[index] = (int16) ( roadLeftX + roadOfDiv );
			newFrame.centDivRX[index] = (int16) ( roadRightX - roadOfDiv );
		}
		else {
			newFrame.centDivLX[index] = 0;
			newFrame.centDivRX[index] = 0;
		}
	}

	private void ground ( int db, int index, ref FrameData newFrame ) {
		int segGround = 12; //Number of segments before color change
		
		int trackIndex = db + index;
		if ( trackIndex % ( segGround * 2 ) > segGround ) {
			newFrame.groundColor[index] = 1;
		}
		else { newFrame.groundColor[index] = 0; }
	}

	public ChunckOfObjects get_shoulder ( ref VRSql db ) {
		int iFirstSeg = (int) Math.round ( trackStart / ROAD_SEG_LENGTH ) + 1;

		ChunckOfObjects obj = db.get_shoulder ( iFirstSeg, iFirstSeg + TRACK_CHUNCK );
		return obj;
	} 
}

public class RoadGenerator : GLib.Object {

	private int deltaX;
	private int deltaY;
	private int tilt;
	private int length;
	private double e = Math.E;

	public RoadGenerator ( int inDeltaX = 0, int inDeltaY = 0, int inTilt = 0, int inLength = 0 ) {
		this.new_delta ( inDeltaX, inDeltaY, inTilt, inLength );
	}

	public void new_delta ( int inDeltaX, int inDeltaY, int inTilt, int inLength ) {
		if (inDeltaX == 0) {
			deltaX = GLib.Random.int_range (-2000, 2000);
		} else { deltaX = inDeltaX; }

		if (inDeltaY == 0) {
			deltaY = GLib.Random.int_range (-2000, 2000);
		} else { deltaY = inDeltaY; }

		if (inTilt == 0) {
			tilt = GLib.Random.int_range (-2000, 2000);
		} else { tilt = inTilt; }

		if (inLength == 0) {
			length = GLib.Random.int_range (10, 12);
		} else { length = inLength; }
	}

	public void new_seg ( ref VRSql db ) {
		//Generate values
		int[] xSegs = this.bend_alg ( 0 );
		int[] ySegs = this.bend_alg ( 1 );
		int[] tilt = this.bend_alg ( 2 );

		//Append the generated values
		int[] newSegScope = db.append_road ( xSegs, ySegs, tilt );

		//Generate objects for the newly created road segment
		GeneratedObjects objects = this.shoulder_objects_alg ( newSegScope );
		db.append_shoulder ( objects );
	}

	private int[] bend_alg ( int option ) {
		int totalDelta = 0;
		int[] bend = new int[this.length];

		switch ( option ) {
		case 0:
			totalDelta = deltaX;
			break;
		case 1:
			totalDelta = 0;//deltaY;
			break;
		case 2:
			totalDelta = 800;
			break;
		}

		float stepSize = 12f / length;
		int absDelta = (int) (1 / ( 1 + Math.pow( e, 6 )) * totalDelta);
		int prevAbsDelta = absDelta;
		int segDelta;
		bend[0] = absDelta;
		float step;
		for ( int i = 1; i < length; i++ ) {
			step = -6 + stepSize * i;
			absDelta = (int) ((1 / ( 1 + Math.pow ( e, -step )) * totalDelta));
			segDelta = absDelta - prevAbsDelta;
			bend[i] = segDelta;
			prevAbsDelta = absDelta;
		}
		return bend;
	}

	private GeneratedObjects shoulder_objects_alg ( int[] segScope ) {
		GeneratedObjects objects = new GeneratedObjects ();
		for ( int i = 0; i < this.length; i++ ) {
			int iObjOnLine = 1;//GLib.Random.int_range ( 1, 2 );
			for ( int j = 0; j < iObjOnLine; j++ ) {
				objects.type.append ( 1 );
				objects.trackID.append ( segScope[0] + i );
				objects.prcFromRoad.append ( GLib.Random.int_range ( -200, 200 ) );
			}
		}
		return objects;
	}
}


public class Character : GLib.Object {
	public double zPosition;
	public double xPosition;
	public double yPosition;

	private int[] acceleration = new int[2];
	private int[] topSpeed = new int[2];
	private int[] decelleration = new int[2];

	private double[] currentSpeed = new double[2];
	private int[] currentDirection = new int[2];
	public int[] reversedDirection = new int[2];

	private int[] timeAccelerationStart = new int[2];
	private int timeSinceLastUpdate;

	public Character ( int[] inAcceleration, int[] inTopSpeed, int[] inDecelleration ) {
		acceleration = inAcceleration;
		topSpeed = inTopSpeed;
		decelleration = inDecelleration;
		currentDirection[0] = 0;
		currentDirection[1] = 0;
		currentSpeed[0] = 0;
		currentSpeed[1] = 0;
		reversedDirection[0] = 0;
		reversedDirection[1] = 0;
		timeSinceLastUpdate = (int) SDL.Timer.get_ticks();
	}

	public void decelerate ( int index ) {
		double previousSpeed = this.currentSpeed[index];
		this.accelerate ( index, reversedDirection[index] );
		if ( Math.fabs(previousSpeed) < Math.fabs(this.currentSpeed[index]) ) {
			this.currentSpeed[index] = 0;
			this.currentDirection[index] = 0;
		}
	}

	public void accelerate ( int index, int direction ) {
		int currentTime = (int) SDL.Timer.get_ticks();
		if ( currentDirection[index] != direction ) {
			timeAccelerationStart[index] = currentTime;
		}

		int accelerationTime = currentTime - timeAccelerationStart[index];
		currentSpeed[index] += ( acceleration[index] * accelerationTime / 1000f ) * direction;

		if ( Math.fabs( currentSpeed[index] ) > topSpeed[index] ) { 
			currentSpeed[index] = topSpeed[index] * direction; 
		}

		currentDirection[index] = direction;
		timeAccelerationStart[index] = currentTime;
	}


	public void move ( ref VRSql db ) {
		int zPosLow = (int) zPosition;

		int currentTime = (int) SDL.Timer.get_ticks();
		zPosition += ( currentSpeed[0] * ( currentTime - timeSinceLastUpdate ) / 1000d );
		if ( zPosition < 0 ) { zPosition = 0; }
		xPosition += ( currentSpeed[1] * ( currentTime - timeSinceLastUpdate ) / 1000d );
		timeSinceLastUpdate = currentTime;

		int zPosHigh;
		int direction;
		if ( zPosition < zPosLow ) {
			zPosHigh = zPosLow;
			zPosLow = (int) zPosition;
			direction = -1;
 		}
		else {
			zPosHigh = (int) zPosition;
			direction = 1;
		}

		int ROAD_SEG_LENGTH = 50;
		int startSeg = (int) Math.round ( zPosLow / ROAD_SEG_LENGTH ) + 1;
	 	int endSeg = (int) Math.round ( zPosHigh / ROAD_SEG_LENGTH ) + 1;

		int relTrackStart = (startSeg) * ROAD_SEG_LENGTH - zPosLow;
		double startDmpPrc = (double) relTrackStart / ROAD_SEG_LENGTH;

		int relTrackEnd = (endSeg) * ROAD_SEG_LENGTH - zPosHigh;
		double endDmpPrc = 1 - (double) relTrackEnd / ROAD_SEG_LENGTH;

		int[,] curTrack = db.get_road( startSeg, endSeg );
		int curTrackEnd = (int)Math.fabs(endSeg - startSeg) + 1;

		if ( endSeg == startSeg ){
			endDmpPrc = Math.fabs( 1 - ( endDmpPrc + startDmpPrc ) );
			this.xPosition += (float) (curTrack[0,0] * endDmpPrc) * direction;
			return;
		}

		curTrack[0, 0] = (int) ((double)curTrack[0, 0] * (startDmpPrc));
		curTrack[0, curTrackEnd -1] = (int) ((double)curTrack[0, curTrackEnd - 1] * (endDmpPrc));
		for ( int i = 0; i < curTrackEnd; i++ ) {
			this.xPosition += (float)curTrack[0, i] * direction;
		}
	}

	public void collision( ref VRSql db, int start, int end ) {
		ChunckOfObjects obj = db.get_shoulder ( start, end );		
		for ( int i = 0; i < obj.type.length; i++ ) {
			double objXStart = obj.prcFromRoad[i] * 800;
			double objXEnd = obj
			if ( ( objXStart < this.xPosition ) && ( objXEnd > this.xPosition ) ) {
				return;
			}
		}
	}

}

