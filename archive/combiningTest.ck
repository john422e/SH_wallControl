/*
for SH@theWende, 2022 - john eagle
2 synths (chan 1, 2) on each pi
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------
1 => int running;
0 => int synthState; // set to 0 when not using, 1 turns on
// sensor vars
150.0 => float thresh;
10.0 => float distOffset; // can set for each sensor if irregularities too much
float dist;
float amp;
0.2 => float minAmp; // for sound level when NOT boosted with sensor
30 => int distSmoother; // val to feed normalize because minAmp is > 0

//"dummyDistance.py" => string sensorProgram;
"d2.py" => string sensorProgram;

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------
OscIn in;
OscOut out;
OscMsg msg;

// local address
"eagle2018.local" => string localIP;

// ports
5000 => int OUT_PORT;
10000 => int IN_PORT;
IN_PORT => in.port;
in.listenAll();
out.dest(localIP, OUT_PORT);
"/w" => string pingAddress;
Shred pinger;

// -----------------------------------------------------------------------------
// AUDIO
// -----------------------------------------------------------------------------
// synth defs
2 => int numSynths;

Blit synths[numSynths];
Envelope synthEnvs[numSynths];

// sound chains
for( 0 => int i; i < numSynths; i++ ) {
    // default to sine tone
    1 => synths[i].harmonics;
    0.05 => synthEnvs[i].time; // TESTING
    synths[i] => synthEnvs[i] => dac.chan(i);
}

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------

fun void pingSensor(int synthNum) {
    
    int pingMS;
    //100 => pingMS;
    250 => pingMS;
    
    pingMS::ms => dur pingInterval; // how long to wait in between pings
    while( true ) {
        <<< "CHUCK: PING!" >>>;
        out.dest(localIP, OUT_PORT);
        out.start(pingAddress);
        synthNum => out.add;
        out.send();
        // time interval between pings
        pingInterval => now;
    }
}

fun void sensorShutdown() {
    out.dest(localIP, OUT_PORT);
    out.start("/shutdown");
    out.send();
    1::second => now;
}

fun void rebootSensor() {
    sensorShutdown();
    1::second => now;
    // kill python processes first
    Std.system("lsof -t -c Python | xargs kill -9");
    1::second => now;
    // now start up sensor program again
    me.dir() + "../python/" + sensorProgram => string targetFile;
    "python3 " + targetFile + " &" => string command;
    Std.system(command);
}

// for normalizing sensor data range
fun float normalize( float inVal, float x1, float x2 ) {
    /*
    for standard mapping:
    x1 = min, x2 = max
    inverted mapping:
    x2 = min, x1 = max
    */
    // catch out of range numbers and cap
    // for inverted ranges
    if( x1 > x2 ) { 
        if( inVal < x2 ) x2 => inVal;
        if( inVal > x1 ) x1 => inVal;
    }
    // normal mapping
    else {
        if( inVal < x1 ) x1 => inVal;
        if( inVal > x2 ) x2 => inVal;
    }
    (inVal-x1) / (x2-x1) => float outVal;
    return outVal;
}

// receiver func
fun void oscListener() {
  <<< "COMBINED (MASTER?) LISTENING ON PORT:", IN_PORT >>>;
  int synth;
  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg) ) {
        <<< msg.address, msg.getInt(0), msg.getFloat(1) >>>;
        // global synth state, arg = 0 or 1 for on/off
        if( msg.address == "/stdSynthState" ) {
            msg.getInt(0) => synthState;
            <<< "STD SYNTH STATE:", synthState >>>;
        }
        msg.getInt(0) => synth;
        // sensor on/off
        // will need a var for sensorState
        if( msg.address == "/sensorInit") {
            // turns sensor program on
            Std.system("lsof -t -i:5000 | xargs kill -9"); // do i need sudo on these commands?
            //<<< "TURNING SENSOR ON" >>>;
            me.dir() + "../python/" + sensorProgram => string targetFile;
            "python3 " + targetFile + " &" => string command;
            Std.system(command);
        }
        if( msg.address == "/rebootSensor" ) rebootSensor();
        if( msg.address == "/sensorClose") {
            // shutds down sensor program
            <<< "SHUTTING DOWN SENSOR" >>>;
            sensorShutdown();
            Std.system("lsof -t -i:5000 | xargs kill -9"); // do i need sudo on these commands?
            Std.system("lsof -t -c Python | xargs kill -9");
            0 => running;
            //Std.system("lsof -t -i:10000 | xargs kill -9"); // this will kill this process to
        }
        // start pinging sensor program
        if( msg.address == "/sensorOn") {
            <<< "SENSOR PINGING ON" >>>;
            spork ~ pingSensor(synth) @=> pinger;
        }
        // stop pinging sensor program
        if( msg.address == "/sensorOff") {
            <<< "SENSOR PINGING OFF" >>>;
            pinger.exit();
        }
        
        // only check this block if synthState === 1
        if( synthState ) {
            // all messages should have an address for event type
            // first arg should always be an int (0 or 1) specifying synth
            //<<< msg.address >>>;
            //msg.getInt(0) => synth;
            
            // individual synth on/off
            if( msg.address == "/synthOn") synthEnvs[synth].keyOn();
            if( msg.address == "/synthOff") synthEnvs[synth].keyOff();
            // synth freq/harmonics
            if( msg.address == "/synthFreq") msg.getFloat(1) => synths[synth].freq;
            if( msg.address == "/synthHarmonics") msg.getInt(1) => synths[synth].harmonics;
            // gain
            if( msg.address == "/synthGain") {
                msg.getFloat(1) => synthEnvs[synth].target;
                synthEnvs[synth].keyOn();
            }
            // end program
            if( msg.address == "/sensorClose" ) 0 => running;
            // get sensor data
            if( msg.address == "/distance" ) {
                msg.getFloat(1) => dist;
                <<< "DISTANCE", dist >>>;
                // turn on sound if value below thresh
                if( dist < thresh && dist > 0.0 ) {
                    normalize(dist, thresh+distSmoother, distOffset) => amp;
                    <<< "sensorAmp", amp >>>;
                    amp => synthEnvs[synth].target;
                    spork ~ synthEnvs[synth].keyOn();
                }
                
                //else { // go to min amp val
                //    minAmp => synthEnvs[synth].target;
                //    spork ~ synthEnvs[synth].keyOn();
                //}
            }
        }
    }
}
}

spork ~ oscListener();

while( running ) {
  1::samp => now;
}
<<< "master?.ck stopping" >>>;