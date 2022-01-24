// get a sound file
me.dir() + "../../audio/desertNight/1.wav" => string sf1;
me.dir() + "../../audio/desertNight/2.wav" => string sf2;
[sf1, sf2] @=> string sfs[];

// sound chain
SndBuf buf => Envelope env => Dyno comp => BPF bpf => Mix2 mix => dac;
Shred loop; // for loop shred

// read in file
sf1 => buf.read;

// set buf position to beginning
0 => buf.pos;
// make buf loop
1 => buf.loop;

// set compressor
comp.limit();
// add makeup gain
50.0 => comp.gain;

// set filter
2000 => bpf.freq;
10.58 => bpf.Q;


// loops a sound buff with smooth envelope
fun void bufPlayLoop( SndBuf buf, Envelope env ) {
    // make sure buff will loop and starts at the beginning
    0 => buf.pos;
    1 => buf.loop;
    // track sample count
    0 => int sampCounter;
    // set env dur
    48 => int envDur;
    envDur::samp => env.duration;
    
    while( buf.loop() ) {
        // start buff
        env.keyOn();
        while( (sampCounter < buf.samples()) && buf.loop() ) {
            if( sampCounter == buf.samples() - envDur ) env.keyOff();
            sampCounter++;
            1::samp => now;
        }
        0 => sampCounter;
    }
    // turn off when loop killed
    env.keyOff();
}

fun void bufChange( SndBuf buf, BPF bpf, Envelope env, string files[] ) {
    <<< "CHANGING BPF STATE" >>>;
    // turn off
    env.keyOff();
    50::ms => now;
    
    Math.random2(0, 1) => int fileChange;
    if( fileChange ) {
        <<< "NEW BUFFER!" >>>;
        Math.random2(0, files.size()-1) => int bufChoice;
        <<< files[bufChoice] >>>;
        0 => buf.loop; // stop current loop
        50::ms => now;
        files[bufChoice] => buf.read; // read in new file
        spork ~ bufPlayLoop(buf, env) @=> loop; // spork new loop
        50::ms => now;
    }
        
    
    
    Math.random2f(100, 2000.0) => bpf.freq;
    // could add Q and amp change here too, but let's see if needed first
    // turn back on
    env.keyOn();
    50::ms => now;
}


// start buf looping
spork ~ bufPlayLoop( buf, env) @=> loop;

// counter
0 => int second_i;
0 => int eventTrigger;
2 => int eventInterval;

while( true ) {
    <<< "SECONDS:", second_i >>>;
    
    Math.random2(0, 1) => buf.loop;
    1 => buf.loop;
    if( buf.loop() == 1 ) {
        //<<< "RUNNING?", loop.done() >>>;
        if( loop.done() ) spork ~bufPlayLoop(buf, env) @=> loop;
    }
    
    if( second_i % eventInterval == 0 ) {
        Math.random2(0, 1) => eventTrigger;
        if( eventTrigger ) spork ~ bufChange(buf, bpf, env, sfs);
    }
    
    second_i++;
    1::second => now;
}