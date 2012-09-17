using SDL;

public class ValaRacer : GLib.Object {
	private VRSql vrdb;
	private Painter paint;
	private GameState state;
	private Character player;
	private KeyboardInput keyInput;
	private RoadProjector road;
	private DrawWorld draw;
	private uint32 fps;

	public ValaRacer () {
		state = new GameState ( 800, 600, 32);
		int[] acceleration = {200, 7000};
		int[] topSpeed = {500, 2000};
		int[] deceleration = {100, 300};
		player = new Character ( acceleration, topSpeed, deceleration, state.xRes, state.roadSegLength );
		paint = new Painter ( state.xRes, state.yRes );
		vrdb = new VRSql ();
		keyInput = new KeyboardInput ();
		road = new RoadProjector ( state.xRes, state.yRes );
		draw = new DrawWorld ( state.xRes, state.yRes );
	}

	private int game_loop () {
		while ( state.running ) {
			
			uint32 timeBefore = SDL.Timer.get_ticks();
			keyInput.get_input ( ref state.running );
			keyInput.modify_game_state ( ref state );
			stdout.printf("TEST: 3 \n"   );
			keyInput.modify_player ( ref player );
			//stdout.printf("TEST: 4 \n"   );
			player.move ( ref vrdb );
			stdout.printf("TEST: 5 \n"   );
			road.xShift = player.xPosition;
			stdout.printf("TEST: 6 \n"   );
			road.trackStart = (int)player.zPosition;
			stdout.printf("TEST: 7 \n"   );
			FrameData newFrame = road.build_road ( ref vrdb );
			stdout.printf("TEST: 8 \n"   );
			ChunckOfObjects obj = road.get_shoulder ( ref vrdb );
			stdout.printf("TEST: 9 \n"   );

			draw.get_frame( newFrame, obj, ref paint );
			stdout.printf("TEST: 10 \n"   );
			paint.flip();

			uint32 timeAfter = SDL.Timer.get_ticks();
			fps=1000/( timeAfter+1 - timeBefore)  ; 
			stdout.printf("FPS: %u\n", fps );
			
			
		}
		return 0;
	}

	static int main (string[] args) {
		var vala_racer = new ValaRacer ();
		return vala_racer.game_loop ();
	}
}
