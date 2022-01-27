/*
sensorSender.ck
--john eagle, jan 2022
*/


// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------
1 => int running;
"d2.py" => string sensorProgram;

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------

// local address
"eagle2018.local" => string localIP;

// ports
5000 => int OUT_PORT;
10000 => int IN_PORT;

OscOut out;
OscIn in;
OscMsg msg;

out.dest(localIP, OUT_PORT);
"/w" => string pingAddress;

IN_PORT => in.port;
in.listenAll(); // start listener

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------

fun void sensorInit() {
    // turns sensor program on
    <<< "sensorSender.ck TURNING SENSOR ON" >>>;
    me.dir() + "../../python/" + sensorProgram => string targetFile;
    "python3 " + targetFile + " &" => string command;
    Std.system(command);
}

fun void setPinging(int synthNum, int pingState) {
    // set pingState to 0 or 1, let python deal with interval
    <<< "sensorSender.ck PINGING:", pingState >>>;
    out.dest(localIP, OUT_PORT);
    out.start(pingAddress);
    synthNum => out.add; // 0 or 1 for synth
    pingState => out.add; // 0 or 1 for state
    
    out.send();
}

fun void sensorShutdown() {
    // send shutdown message so sensor program can properly shutdown
    <<< "sensorSender.ck SHUTTING DOWN SENSOR" >>>;
    out.dest(localIP, OUT_PORT);
    out.start("/shutdown");
    out.send();
    1::second => now;
}

fun void rebootSensor() {
    // reboot in the case of an error
    // kill python processes first
    Std.system("pkill python3");
    1::second => now;
    // now start up sensor program again
    me.dir() + "../../python/" + sensorProgram => string targetFile;
    "python3 " + targetFile + " &" => string command;
    Std.system(command);
}
    

fun void oscListener() {
    <<< "sensorSender.ck SENSOR CTL LISTENING ON PORT", IN_PORT >>>;
    int synth;
    while( true ) {
        in => now; // wait for a message
        while( in.recv(msg)) {
            // addresses coming through are either /sensorOn, /sensorOff,
            // or /distance followed by a float arg
            <<< "sensorSender.ck", msg.address >>>;
            
            // sensor on/off
            // will need a var for sensorState
            if( msg.address == "/sensorInit") sensorInit();
            
            if( msg.address == "/rebootSensor" ) rebootSensor();
           
            if( msg.address == "/endProgram") {
                // shutds down sensor program
                sensorShutdown();
                0 => running;
            }
            // start pinging sensor program
            if( msg.address == "/sensorOn") setPinging(synth, 1);

            // stop pinging sensor program
            if( msg.address == "/sensorOff") setPinging(synth, 0);

            // distance data
            if( msg.address == "/distance") <<< "sensorSender.ck", msg.getFloat(1) >>>; // uncomment this only for testing
        }
    }
}

spork ~ oscListener();

while( running ) {
    1::samp => now;
}

<<< "sensorSender.ck stopping" >>>;