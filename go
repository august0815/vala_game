#!/bin/bash
#rm VRDB

#sqlite3 VRDB << EOF
#CREATE TABLE track (id INTEGER PRIMARY KEY, x INTEGER, y INTEGER);
#INSERT INTO track (x ,y ) VALUES (1, 1);
#EOF
cd _build_/default/src
LD_LIBRARY_PATH=$PWD ./race
