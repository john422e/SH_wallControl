<<< "ADDING FB SENDER TO SERVER" >>>;

1 => int running;
"localServer.ck" => string fn;

me.dir() => string dir;

// START A SERVER TO CONTROL FB RECEIVER

// OSC
OscIn in;
OscMsg msg;
9998 => int port;
port => in.port;
in.listenAll();

int fbState;
int fbid;

fun void oscListener() {
    <<< fn, "LISTENING ON PORT:", port >>>;
    while( true ) {
        in => now; // wait for message
        while( in.recv(msg) ) {
            if( msg.address == "/fbSenderState" ) {
                msg.getInt(0) => fbState;
                if( fbState == 1 ) {
                    // FB MODE
                    Machine.add(dir + "fbSender.ck") => fbid;
                }
                if( fbState == 0) {
                    // TURN FB OFF
                    Machine.remove(fbid);
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