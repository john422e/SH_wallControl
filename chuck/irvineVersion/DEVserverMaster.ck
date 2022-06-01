/*
for SH@UCIrvine, June 2, 2022 - john eagle
*/

1 => int running;
"serverMaster.ck" => string fn;

me.dir() => string dir;

// START A SERVER TO CONTROL FB RECEIVER

// OSC
OscIn in;
OscMsg msg;
9999 => int port;
port => in.port;
in.listenAll();

int sensorState;
int sensorID;

int pulseState;
int pulseID;

int ternaryState;
int ternaryID;

int roomModeState;
int roomModeID;

int fieldplayState;
int fieldplayID;

int fbState;
int fbID;

int alarmState;
int alarmID;

int newState;

fun void oscListener() {
    <<< fn, "LISTENING ON PORT:", port >>>;
    while( true ) {
        in => now; // wait for message
        while( in.recv(msg) ) {
            
            // SENSOR PROGRAM
            if( msg.address == "/sensorState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != sensorState) { // only set it and act if it's a change
                    newState => sensorState;
                    if( sensorState == 1 ) {
                        // add sensorSender.ck to server and assign it an ID
                        Machine.add(dir + "mockSensorSender.ck") => sensorID;
                        <<< "ADDING SENSOR SENDER", sensorID >>>;
                    }
                    if( sensorState == 0 ) {
                        // remove sensorSender.ck from server
                        Machine.remove(sensorID);
                        <<< "REMOVING SENSOR SENDER", sensorID >>>;
                    }
                }
            }
            
            // PULSE SYNTH
            if( msg.address == "/pulseState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != pulseState ) { // only set it and act if it's a change
                    newState => pulseState;
                    if( pulseState == 1 ) {
                        // add pulseSynth.ck to server and assign it an ID
                        Machine.add(dir + "pulseSynth.ck") => pulseID;
                        <<< "ADDING PULSE SYNTH", pulseID >>>;
                    }
                    if( pulseState == 0 ) {
                        // remove pulseSynth.ck from server
                        Machine.remove(pulseID);
                        <<< "REMOVING PULSE SYNTH", pulseID >>>;
                    }
                }
            }
            
            // STD SYNTH (TERNARY AND BP WALL MODES)
            if( msg.address == "/ternaryState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != ternaryState ) { // only set it and act if it's a change
                    newState => ternaryState;
                    if( ternaryState == 1 ) {
                        // add stdSynth.ck to server and assign it an ID
                        Machine.add(dir + "stdSynth.ck") => ternaryID;
                        <<< "ADDING STD SYNTH (TERNARY MODE)", ternaryID >>>;
                    }
                    if( ternaryState == 0 ) {
                        // remove stdSynth.ck from server
                        Machine.remove(ternaryID);
                        <<< "REMOVING STD SYNTH (TERNARY MODE)", ternaryID >>>;
                    }
                }
            }
            
            // STD SYNTH (BP WALL MODE)
            if( msg.address == "/roomModeState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != roomModeState ) { // only set it and act if it's a change
                    newState => roomModeState;
                    if( roomModeState == 1 ) {
                        // add stdSynth.ck to server and assign it an ID
                        Machine.add(dir + "stdSynth.ck") => roomModeID;
                        <<< "ADDING STD SYNTH (ROOM MODE)", roomModeID >>>;
                    }
                    if( roomModeState == 0 ) {
                        // remove stdSynth.ck from server
                        Machine.remove(roomModeID);
                        <<< "REMOVING STD SYNTH (ROOM MODE)", roomModeID >>>;
                    }
                }
            }     
            
            // FIELDPLAY
            if( msg.address == "/fieldplayState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != fieldplayState ) { // only set it and act if it's a change
                    newState => fieldplayState;
                    if( fieldplayState == 1) {
                        // add fieldPlay.ck to server and assign it an ID
                        Machine.add(dir + "fieldPlay.ck") => fieldplayID;
                        <<< "ADDING FIELDPLAY SYNTH", fieldplayID >>>;
                    }
                    if( fieldplayState == 0) {
                        // remove fieldPlay.ck from server
                        Machine.remove(fieldplayID);
                        <<< "REMOVING FIELDPLAY SYNTH", fieldplayID >>>;
                    }
                }
            }
            
            
            // ALARM
            if( msg.address == "/alarmState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != alarmState ) { // only set it and act if it's a change
                    newState => alarmState;
                    if( alarmState == 1 ) {
                        <<< "ADDING ALARM SYNTH" >>>;
                        // add alarmSynth.ck to server
                        Machine.add(dir + "alarmSynth.ck") => alarmID;
                    }
                    if( alarmState == 0) {
                        <<< "REMOVING ALARM SYNTH" >>>;
                        // remove alarmSynth.ck from server
                        Machine.remove(alarmID);
                    }
                }
            }          
            
            
            if( msg.address == "/fbReceiverState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != fbState ) { // only set it and act if it's a change
                    newState => fbState;
                    if( fbState == 1 ) {
                        // FB MODE
                        Machine.add(dir + "fbReceiverSynth.ck") => fbID;
                    }
                    if( fbState == 0) {
                        // TURN FB OFF
                        Machine.remove(fbID);
                    }
                }
            }
            if( msg.address == "/endProgram" ) 0 => running;
        }
    }
}


// MAIN
spork ~ oscListener();

while( running ) {
    1::second => now;
}

<<< fn, "stopping" >>>;