/*

*/


// sender.ck
// Eric Heep

/*
sine tone freq per pi
sine tone gain per pi

mic volume per pi
lookback delay time per pi
packet length per pi
threshold per pi

cutoff freq per pi
resonance Q per pi
envelope length
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------

"fbSender.ck" => string thisFile;
1 => int running;
0 => int senderState;

// constants
512 => int BUFFER_SIZE;
50 => int maxDb;

// --------------------------------------------------------------
// osc out ------------------------------------------------------
// --------------------------------------------------------------

// ip addresses

[
"pione.local",
"pitwo.local",
"pithree.local",
"pifour.local",
"pifive.local",
"pisix.local"
//"piseven.local",
//"pieight.local"
] @=> string IP[];

//[ "127.0.0.1" ] @=> string IP[];

IP.size() => int NUM_IPS;
IP.size() => int NUM_PIS;

// port is the same for all outgoing messages
10000 => int OUT_PORT;

// address is the same for all outgoing messages
"/m" => string ADDRESS;

// osc out to Raspberry Pis
OscOut out[NUM_PIS];

// determines our packet length for outgoing messages
dur packetLength[NUM_PIS];

// --------------------------------------------------------------
// osc in -------------------------------------------------------
// --------------------------------------------------------------

OscIn in;
OscMsg msg;

// the port for the incoming messages
7400 => int IN_PORT;
IN_PORT => in.port;
in.listenAll();

// --------------------------------------------------------------
// microphone audio ---------------------------------------------
// --------------------------------------------------------------

Gain gain[NUM_PIS];
HPF hp[NUM_PIS];
LPF lp[NUM_PIS];
ResonZ res[NUM_PIS];
Delay del[NUM_PIS];
OnePole pole[NUM_PIS];
Shred envFollow;

// we'll try this out
dur delayLength[NUM_PIS];
float threshold[NUM_PIS];


// --------------------------------------------------------------
// FUNCTIONS
// --------------------------------------------------------------



fun void endProgram() {
    <<< thisFile, "END PROGRAM" >>>;
    // ends loop and stops program
    0 => running;
}

// receiver function -> everything is triggered from this
fun void oscListener() {
  <<< thisFile, "FEEDBACK SENDER LISTENING ON PORT:", IN_PORT >>>;

  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg)) {
        //<<< thisFile, msg.address, msg.getInt(0) >>>;

        // global state, arg = 0 or 1 for on/off
        if( msg.address == "/senderState" ) msg.getInt(0) => senderState;

        // end program
        if( msg.address == "/endProgram" ) endProgram();

    }
  }
}

// --------------------------------------------------------------
// initialize ---------------------------------------------------
// --------------------------------------------------------------

for (0 => int i; i < NUM_PIS; i++) {
    // sound chain
	//SinOsc mic => gain[i] => res[i] => del[i] => blackhole;
    adc => gain[i] => res[i] => del[i] => blackhole;
    //adc.chan(1) => gain[i];
	//mic => gain[i] => lp[i] => hp[i] => del[i] => blackhole;
	//mic => gain[i] => del[i] => blackhole;
	adc => pole[i] => blackhole;
    //adc.chan(1) => pole[i] => blackhole;

	// delay of adc
	500::ms => delayLength[i]; // 48000 / 512 = 93.75

	// delay stuff
	del[i].max(100::ms);
	del[i].delay(100::ms);

	hp[i].freq(0.1);
	lp[i].freq(10000.0);

	// following
	3 => pole[i].op;
	0.9999 => pole[i].pole;

	// thresholds in decibels
	10 => threshold[i]; // started at 10, try going higher?

	// this determines how much audio is send through in milliseconds
	500::ms => packetLength[i]; // started at 500
    
    // filter
    1.0 => res[i].Q;
}

for (0 => int i; i < NUM_IPS; i++) {
	// start the envelope follower
	spork ~ envelopeFollower(i);

	// set ip and port for each osc out
	out[i].dest(IP[i], OUT_PORT);

	// set buffer_size
	out[i].start("/bufferSize");
	out[i].add(BUFFER_SIZE);
	out[i].send();

}

// envelope follower
fun void envelopeFollower(int idx) {
    
    while (running) {
        
        while ( (Std.rmstodb(pole[idx].last()) < threshold[idx]) || (Std.rmstodb(pole[idx].last()) > maxDb)) {
            // advance time while mic is below threshold val (don't send anything)
            1::samp => now;
            <<< "below" >>>;
        }
        
        <<< "ABOVE THRESH, Sound.", "" >>>;
        
        send(idx); // send to one pi at a time
        now => time past;
        // keep sending until whole packet is sent
        while (now < past + packetLength[idx]) send(idx);
        //1::ms => now;
    }
    //1::ms => now;
}

// sends out audio in 512 sample blocks
fun void send(int idx) {
    <<< "SENDING" >>>;
    out[idx].start(ADDRESS);
    
    for (0 => int j; j < BUFFER_SIZE; j++) {
        out[idx].add(del[idx].last());
        
        1::samp => now;
    }
    
    out[idx].send();
}

// start OSC server
spork ~ oscListener();

// --------------------------------------------------------------
// loop forever
// --------------------------------------------------------------

while (running) {
	1::second => now;
}
