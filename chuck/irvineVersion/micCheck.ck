// mic-in to audio out

// the patch
adc => Gain g => dac;

// infinite time-loop
while( true )
{
    <<< "TIME" >>>;
    // advance time
    100::ms => now;
}
