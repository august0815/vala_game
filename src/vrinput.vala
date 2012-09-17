using SDL;

public class KeyboardInput : GLib.Object {

	private bool[] keysHeld = new bool[323];
	private SDL.Event event = SDL.Event ();

	public KeyboardInput () {
		for ( int i = 0; i < keysHeld.length -1; i++ ) {
			keysHeld[i] = false;
		}
	}

	public void get_input ( ref bool running ) {
        while (Event.poll (out event) == 1) {
            switch (event.type) {
            case EventType.QUIT:
                running = false;
                break;
            case EventType.KEYDOWN:
				keysHeld[event.key.keysym.sym] = true;
                break;
            case EventType.KEYUP:
				keysHeld[event.key.keysym.sym] = false;
                break;
            }
        }
	}

	public void modify_game_state ( ref GameState state ) {
		if ( keysHeld[113] ) { // Q
			state.running = false;
		}
	}

	public void modify_player ( ref Character player ) {
/*		switch ( 1 ) {
		case keysHeld[119]:
			player.accelerate ( 0, 1 );
		case keysHeld[115]:
			player.accelerate ( 0, -1 );
		case default:
			player.deccelerate ( 0 );
		}
*/
		if ( keysHeld[119] ) { // W
			player.accelerate (0, 1);
			player.reversedDirection[0] = -1;
		}
		if ( keysHeld[115] ) { // S
			player.accelerate (0, -1);
			player.reversedDirection[0] = 1;
		}
		if ( !keysHeld[119] && !keysHeld[115] ) {
			player.decelerate ( 0 );
		}

		if ( keysHeld[97] ) { // A
			player.accelerate (1, 1);
			player.reversedDirection[1] = -1;
		}
		if ( keysHeld[100] ) { // D
			player.accelerate (1, -1);
			player.reversedDirection[1] = 1;
		}
		if ( !keysHeld[97] && !keysHeld[100] ) {
			player.decelerate ( 1 );
		}

	}
}
