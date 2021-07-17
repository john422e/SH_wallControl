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
~hosts[0].sendMsg( '/sinePhase', 2pi); // +- 8pi

-pi.postln;

SinOsc.ar