import std.stdio;
import std.net.curl : HTTP;

import entity;
import network;
import listener;

void main() {
	Request req1 = Request(
		"https://bagomot.keybase.pub/%D0%9C%D0%B0%D0%B3%D0%B0%D0%B7%D0%B8%D0%BD.png",
		HTTP.Method.get,
		"test1.png"
	);

	Request req2 = Request(
		"https://httpbin.org/image/png",
		HTTP.Method.get,
		"test2.png"
	);

	Request req3 = Request(
		"https://speed.hetzner.de/100MB.bin",
		HTTP.Method.get,
		"100MB.bin"
	);

	Request[] requests = [
		req2,
		req1,
	];

	// test 1 file async download
	HttpConn conn = Network.download(req1);
	conn.addEventListener(new ProgressListener);
	conn.executeInNewThread(() { writeln("Done!"); });

	// test multifile async download
	// Network.multiDownload(requests, new MultifileProgressListener);

	// test text response
	// auto r1 = Request("https://httpbin.org/get");
	// writeln(Network.getAsText(Network.conn(r1), r1));
}
