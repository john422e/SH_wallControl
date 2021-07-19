(
var port=10002;
~hostnames = [
	//"pione.local",
	//"pitwo.local",
	//"pithree.local",
	//"pifour.local",
	//"pifive.local",
	//"pisix.local",
	//"piseven.local",
	//"pieight.local",
	"eagle2018.local"
];
~hosts = Array.new(9);
// set up each host with hostname and port

for( 0, ~hostnames.size-1, {
	arg i;
	var host;
	[~hostnames[i], port].postln;
	host = NetAddr.new(~hostnames[i], port);
	~hosts.add(host);
});
)

~hosts[0].sendMsg( '/sineFreq', 200.0);
~hosts[0].sendMsg( '/sineGain', 0.5);
~hosts[0].sendMsg( '/sinePhase', -8pi); // +- 8pi
(
~hosts.do( {
	arg host;
	host.sendMsg( '/modFreq', 2.0);
	host.sendMsg( '/carrFreq', 400.0);
	host.sendMsg( '/gain', 0.8);
	host.sendMsg( '/sinModOn' );
	host.sendMsg( '/pulseModOn' );
	host.sendMsg( '/noteOn' );
	//host.sendMsg( '/noteOff' );
});
)


~hosts[0].sendMsg( '/modFreq', 2.0);
~hosts[0].sendMsg( '/carrFreq', 400.0);
~hosts[0].sendMsg( '/gain', 0.8);
~hosts[0].sendMsg( '/sinModOn' );
~hosts[0].sendMsg( '/pulseModOn' );
~hosts[0].sendMsg( '/noteOn' );
~hosts[0].sendMsg( '/noteOff' );
~hosts[0].sendMsg( '/modPhase', 8pi);

-pi.postln;

SinOsc.ar