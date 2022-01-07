// --------------------------------------------------------------
// osc out ------------------------------------------------------
// --------------------------------------------------------------

// ip address
"eagle2018.local" => string IP;

// port is the same for all outgoing messages
10002 => int OUT_PORT;

// osc out to Raspberry Pis
OscOut out;
out.dest(IP, OUT_PORT);

fun void send( string address, int arg1, float arg2, float arg3 ) {
    out.start(address);
    out.add( arg1 );
    out.add( arg2 );
    out.add( arg3 );
    out.send();
}


send( "/noteOn", 1, 1.5, 1.6 );

1::second => now;