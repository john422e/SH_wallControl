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

int stdSynthState;
int stdSynthID;

int fieldplayState;
int fieldplayID;

int fbState;
int fbID;

int alarmState;
int alarmID;

fun void oscListener() {
    <<< fn, "LISTENING ON PORT:", port >>>;
    while( true ) {
        in => now; // wait for message
        while( in.recv(msg) ) {
            
            // SENSOR PROGRAM
            if( msg.address == "/sensorState" ) {
                msg.getInt(0) => sensorState; // msg is 0 or 1 and sets to state
                if( sensorState == 1 ) {
                    <<< "ADDING SENSOR SENDER" >>>;
                    // add sensorSender.ck to server and assign it an ID
                    Machine.add(dir + "sensorSender.ck") => sensorID;
                }
                if( sensorState == 0 ) {
                    <<< "REMOVING SENSOR SENDER" >>>;
                    // remove sensorSender.ck from server
                    Machine.remove(sensorID);
                }
            }
            
            // PULSE SYNTH
            if( msg.address == "/pulseState" ) {
                msg.getInt(0) => pulseState; // msg is 0 or 1 and sets to state
                if( pulseState == 1 ) {
                    <<< "ADDING PULSE SYNTH" >>>;
                    // add pulseSynth.ck to server and assign it an ID
                    Machine.add(dir + "pulseSynth.ck") => pulseID;
                }
                if( pulseState == 0 ) {
                    <<< "REMOVING PULSE SYNTH" >>>;
                    // remove pulseSynth.ck from server
                    Machine.remove(pulseID);
                }
            }
            
            // STD SYNTH (TERNARY AND BP WALL MODES)
            if( msg.address == "/stdSynthState" ) {
                msg.getInt(0) => stdSynthState; // msg is 0 or 1 and sets to state
                if( stdSynthState == 1 ) {
                    <<< "ADDING STD SYNTH" >>>;
                    // add stdSynth.ck to server and assign it an ID
                    Machine.add(dir + "stdSynth.ck") => stdSynthID;
                }
                if( stdSynthState == 0 ) {
                    <<< "REMOVING STD SYNTH" >>>;
                    // remove stdSynth.ck from server
                    Machine.remove(stdSynthID);
                }
            }
                    
            
            // FIELDPLAY
            if( msg.address == "/fieldplayState" ) {
                msg.getInt(0) => fieldplayState; // msg is 0 or 1 and sets to state
                if( fieldplayState == 1) {
                    <<< "ADDING FIELDPLAY SYNTH" >>>;
                    // add fieldPlay.ck to server and assign it an ID
                    Machine.add(dir + "fieldPlay.ck") => fieldplayID;
                }
                if( fieldplayState == 0) {
                    <<< "REMOVING FIELDPLAY SYNTH" >>>;
                    // remove fieldPlay.ck from server
                    Machine.remove(fieldplayID);
                }
            }
            
            
            // ALARM
            if( msg.address == "/alarmState" ) {
                msg.getInt(0) => alarmState; // msg is 0 or 1 and sets to state
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
            
            
            if( msg.address == "/fbReceiverState" ) {
                msg.getInt(0) => fbState;
                if( fbState == 1 ) {
                    // FB MODE
                    Machine.add(dir + "fbReceiverSynth.ck") => fbID;
                }
                if( fbState == 0) {
                    // TURN FB OFF
                    Machine.remove(fbID);
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