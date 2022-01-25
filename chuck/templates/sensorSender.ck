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
fun void setPinging(int synthNum, int pingState) {
    // set pingState to 0 or 1, let python deal with interval
    <<< "PINGING:", pingState >>>;
    out.dest(localIP, OUT_PORT);
    out.start(pingAddress);
    synthNum => out.add; // 0 or 1 for synth
    pingState => out.add; // 0 or 1 for state
    
    out.send();
}

fun void sensorShutdown() {
    out.dest(localIP, OUT_PORT);
    out.start("/shutdown");
    out.send();
    1::second => now;
}

fun void rebootSensor() {
    // kill python processes first
    Std.system("lsof -t -c Python | xargs kill -9");
    1::second => now;
    // now start up sensor program again
    me.dir() + "../../python/" + sensorProgram => string targetFile;
    "python3 " + targetFile + " &" => string command;
    Std.system(command);
}
    

fun void oscListener() {
    <<< "SENSOR CTL LISTENING ON PORT", IN_PORT >>>;
    int synth;
    while( true ) {
        in => now; // wait for a message
        while( in.recv(msg)) {
            // addresses coming through are either /sensorOn, /sensorOff,
            // first arg should always be an int (0 or 1) specifying synth
            // or /distance followed by a float arg
            //<<< msg.address >>>;
            msg.getInt(0) => synth;
            
            // sensor on/off
            // will need a var for sensorState
            if( msg.address == "/sensorInit") {
                // turns sensor program on
                Std.system("lsof -t -i:5000 | xargs kill -9"); // do i need sudo on these commands?
                <<< "TURNING SENSOR ON" >>>;
                
                me.dir() + "../../python/" + sensorProgram => string targetFile;
                "python3 " + targetFile + " &" => string command;
                Std.system(command);
            }
            if( msg.address == "/rebootSensor" ) rebootSensor();
            if( msg.address == "/endProgram") {
                // shutds down sensor program
                <<< "SHUTTING DOWN SENSOR" >>>;
                sensorShutdown();
                Std.system("lsof -t -i:5000 | xargs kill -9"); // do i need sudo on these commands?
                Std.system("lsof -t -c Python | xargs kill -9");
                0 => running;
                //Std.system("lsof -t -i:10000 | xargs kill -9"); // this will kill this process too
            
            }
            // start pinging sensor program
            if( msg.address == "/sensorOn") {
                <<< "SENSOR PINGING ON" >>>;
                setPinging(synth, 1);
            };
            // stop pinging sensor program
            if( msg.address == "/sensorOff") {
                <<< "SENSOR PINGING OFF" >>>;
                setPinging(synth, 0);
            };
            // distance data
            if( msg.address == "/distance") <<< msg.getFloat(1) >>>;
        }
    }
}

spork ~ oscListener();

while( running ) {
    1::samp => now;
}

<<< "sensorSender.ck stopping" >>>;