SinOsc s => Envelope e => Pan2 p => dac;

0.9 => dac.gain;

-1.0 => p.pan;
100.0 => s.freq;

int step;

if( me.args() > 0 ) Std.atoi(me.arg(0)) => step;
else 1 => step;


e.keyOn();

while( s.freq() < 3000.0 ) {
    s.freq() + step => s.freq;
    <<< s.freq() >>>;
    100::ms => now;
}