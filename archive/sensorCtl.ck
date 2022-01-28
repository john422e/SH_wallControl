/*
for SH@theWende, 2022 - john eagle
controls
*/

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------
OscIn in;
OscOut out;
OscMsg msg;

12345 => int listenPort;
5000 => int pingPort;
"127.0.0.1" => string localIP;
"/w" => string pingAddress;
Shred pinger;

listenPort => in.port;
in.listenAll();


// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------
fun void pingSensor() {
  while( true ) {
    out.dest(localIP, pingPort);
    out.start(pingAddress);
    out.send();
    // time interval between pings
    250::ms => now;
  }
}

fun void oscListener() {
  <<< "SENSOR CTL LISTENING ON PORT", listenPort >>>;
  int synth;
  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg)) {
      // addresses coming through are either /sensorOn, /sensorOff,
      // or /distance followed by a float arg
      <<< msg.address >>>;

      // sensor on/off
      // will need a var for sensorState
      if( msg.address == "/sensorInit") {
        // turns sensor program on
        me.dir() + "../python/dummyDistance.py" => string targetFile;
        "python3 " + targetFile + " &" => string command;
        spork ~ Std.system(command);
      }
      if( msg.address == "/sensorClose") {
        // shutds down sensor program
        Std.system("sudo lsof -i :5000") => int PID;
        Std.system("sudo kill " + Std.itoa(PID));
      }
      // start pinging sensor program
      if( msg.address == "/sensorOn") {
        <<< "SENSOR PINGING ON" >>>;
        spork ~ pingSensor() @=> pinger;
      };
      // stop pinging sensor program
      if( msg.address == "/sensorOff") {
        <<< "SENSOR PINGING OFF" >>>;
        pinger.exit();
      };
      // distance data
      if( msg.address == "/distance") <<< msg.getFloat(0) >>>;
    }
  }
}

spork ~ oscListener();

while( true ) {
  1::samp => now;
}
