using SDL;

public class ValaRacer : GLib.Object {
	private VRSql vrdb;
	private Painter paint;
	private GameState state;
	private Character player;
	private KeyboardInput keyInput;
	private RoadProjector road;
	private DrawWorld draw;

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
			keyInput.modify_player ( ref player );
			player.move ( ref vrdb );
			road.xShift = player.xPosition;
			road.trackStart = (int)player.zPosition;

			FrameData newFrame = road.build_road ( ref vrdb );
			ChunckOfObjects obj = road.get_shoulder ( ref vrdb );

			draw.get_frame( newFrame, obj, ref paint );
			paint.flip();

			uint32 timeAfter = SDL.Timer.get_ticks();
//			stderr.printf("FPS: %u\n", ( 1000 / ( timeAfter - timeBefore ) ) );
		}
		return 0;
	}

	static int main (string[] args) {
		var vala_racer = new ValaRacer ();
		return vala_racer.game_loop ();
	}
}