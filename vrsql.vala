using Sqlite;
using Gtk;

public class VRSql : GLib.Object {

	private Database db;
	private Statement stmt;
	private int rc;
	private const string DISK_DB = "VRDB";
	
	public VRSql() {
		if (!FileUtils.test (DISK_DB, FileTest.IS_REGULAR)) {
			stderr.printf ("Database %s does not exist or is directory\n", DISK_DB);
		}

		rc = Database.open ("", out db);
		if (rc != Sqlite.OK) {
			stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
		}

		db.exec("CREATE TABLE track ( id INTEGER PRIMARY KEY, x INTEGER, y INTEGER )", null, null);
		db.exec("CREATE TABLE shoulder ( id INTEGER PRIMARY KEY, track_id INTEGER, type INTEGER, prc_of_road INTEGER )", null, null);
		db.exec("ATTACH \"./VRDB\" AS disk", null, null);
		db.exec("INSERT INTO track SELECT * FROM disk.track", null, null);
		db.exec("DROP disk", null, null);
	}
	
	public bool check_scope(int segStart, int segEnd) {
		rc = db.prepare_v2 ( "SELECT EXISTS ( SELECT 1 FROM track WHERE id = " + segStart.to_string() + " )", -1, out stmt, null );
		stmt.step ();
		int xPosExists = stmt.column_int (0);

		rc = db.prepare_v2 ( "SELECT EXISTS ( SELECT 1 FROM track WHERE id = " + segEnd.to_string() + " )", -1, out stmt, null );
		stmt.step ();
		int yPosExists = stmt.column_int (0);
		
		if ( ( xPosExists == 1 ) && ( yPosExists == 1) ) {
			return true;
		}
		return false;				
	}

	public int[,] get_road( int segStart, int segEnd ) {

		rc = db.prepare_v2 ( "SELECT COUNT(*) FROM track WHERE id BETWEEN " + segStart.to_string() + 
							 " AND " + segEnd.to_string(), -1, out stmt, null );
		rc = stmt.step();
//		stderr.printf("asd:%i\n", stmt.column_int ( 0 ));

		if ( rc == 1 ) { stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ()); };


		rc = db.prepare_v2 ( "SELECT * FROM track WHERE id BETWEEN " + segStart.to_string() + 
							 " AND " + segEnd.to_string(), -1, out stmt, null );

		if ( rc == 1 ) { stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ()); };

		int colsInTbl = stmt.column_count ();

		int[,] trackData = new int[3, segStart + segEnd + 1];
		
		int i = 0;
		int colData = 0;
		do {
			rc = stmt.step ();
			switch ( rc ) {
			case Sqlite.DONE:
				break;
			case Sqlite.ROW:
				for ( int curCol = 1; curCol < colsInTbl; curCol++ ) {
					colData = stmt.column_int ( curCol );
					trackData[curCol - 1, i] = colData; 
				}
				i++;
				break;
			default:
				stderr.printf("Error: %d, %s\n", rc, db.errmsg ());
		  		break;
			}
		} while ( rc == Sqlite.ROW );
		return trackData;
	}

	public int[] append_road (int[] roadXSegs, int[] roadYSegs) {
		int[] segIndex = new int[2];
		rc = db.prepare_v2 ( "SELECT MAX(id) FROM track", -1, out stmt, null );
		stmt.step ();
		segIndex[0] = stmt.column_int (0) + 1;
		
		string sqlStmt = "";
		for ( int i = 0; i < roadXSegs.length; i++ ) {
			sqlStmt += "INSERT INTO track (x, y) VALUES (" + roadXSegs[i].to_string() + ", " 
			+ roadYSegs[i].to_string() + ");";
		}
		db.exec(sqlStmt, null, null);

		rc = db.prepare_v2 ( "SELECT MAX(id) FROM track", -1, out stmt, null );
		stmt.step ();
		segIndex[1] = stmt.column_int (0);

		return segIndex;
	}

	public void append_shoulder ( GeneratedObjects objects ) {
		string sqlStmt = "";
	
		for ( int i = 0; i < objects.type.length (); i++ ) {
			
			sqlStmt += "INSERT INTO shoulder (track_id, type, prc_of_road) VALUES (" + objects.trackID.nth_data (i).to_string () + ", "
			+ objects.type.nth_data (i).to_string () + ", " + objects.prcFromRoad.nth_data (i).to_string () + ");";
		}
		db.exec(sqlStmt, null, null);
	}

	public ChunckOfObjects get_shoulder ( int segStart, int segEnd ) {

		rc = db.prepare_v2 ( "SELECT COUNT(*) FROM shoulder WHERE track_id BETWEEN " + segStart.to_string() + " AND " + segEnd.to_string(), -1,
							 out stmt, null );

		if ( rc == 1 ) { stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ()); };

		rc = stmt.step ();
		int nIndex = stmt.column_int ( 0 );
		ChunckOfObjects objs = new ChunckOfObjects ( nIndex );

		rc = db.prepare_v2 ( "SELECT * FROM shoulder WHERE track_id BETWEEN " + segStart.to_string() + " AND " + segEnd.to_string(), -1,
							 out stmt, null );

		if ( rc == 1 ) { stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ()); };

		int colsInTbl = stmt.column_count ();

		int i = 0;
		do {
			rc = stmt.step ();
			switch ( rc ) {
			case Sqlite.DONE:
				break;
			case Sqlite.ROW:

				for ( int curCol = 1; curCol < colsInTbl; curCol++ ) {
					int colData = (int) stmt.column_int ( curCol );
					switch ( curCol ) {
					case 1:
						objs.trackID[i] = (colData - segStart) + 1;
						break;
					case 2:
						objs.type[i] = colData;
						break;
					case 3:
						objs.prcFromRoad[i] = colData;
						break;
					}
				}
				i++;
				break;
			default:
				stderr.printf("Error: %d, %s\n", rc, db.errmsg ());
		  		break;
			}
		} while ( rc == Sqlite.ROW );
		return objs;
	}
}