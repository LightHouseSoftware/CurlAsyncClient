import std.stdio;
import std.concurrency;

import entity;
import http;
import listener;

void main() {
	Request req1 = new Request(
		"https://bagomot.keybase.pub/%D0%9C%D0%B0%D0%B3%D0%B0%D0%B7%D0%B8%D0%BD.png");
	//req1.addEventListener(new ProgressListener());
	req1.addEventListener(new SaveListener("test1.png"));
	//req1.addEventListener(new StatusListener());
	//req1.execute(() { writeln("Done!"); });

	//download(req1, () { writeln("Done!"); });

	Request req2 = new Request("https://httpbin.org/image/png");
	req2.addEventListener(new SaveListener("test2.png"));
	//req2.addEventListener(new StatusListener());
	//req2.addEventListener(new ProgressListener());

	Request req3 = new Request(
		"https://speed.hetzner.de/100MB.bin");
	req3.addEventListener(new SaveListener("100MB.bin"));

	Request[] requests = [
		req1,
		req2,
		req3
	];

	download(requests);
}

// void download(Request request, Callback callback = null) {
// 	import std.parallelism;

// 	auto r = task(&request.execute, callback);
// 	r.executeInNewThread();
// }

void download(Request[] requests, Callback callback = null) {
	import std.parallelism;
	import std.format;
	import std.exception;
	import core.thread;

	new Thread(() {
		foreach (Request request; requests.parallel) {
			request.addEventListener(new MultifileProgressListener(thisTid));
			request.execute();
		}

		Progress[Tid] progresses;
		size_t finished = 0;
		while (
			finished != requests.length) {
			receive(
				(LinkTerminated arg) {
				++finished;

				// Проверьте, не завершается ли этот поток преждевременно
				enforce((arg.tid in progresses) &&
				(progresses[arg.tid].current == progresses[arg.tid].total),
				format!"Thread %s exited unexpectedly"(arg.tid));
			},

				(Tid childTid, size_t total, size_t current) {
				progresses[childTid] = Progress(total, current);
				display(progresses);
			});
		}
	}).start;
}

// void download(Request[] requests, Callback callback = null) {
// 	import std.exception;
// 	import std.format;
// 	import core.thread;
// 	import std.parallelism;

// 	auto pool = new TaskPool();

// 	foreach (Request request; requests) {
// 		request.addEventListener(new MultifileProgressListener(thisTid));
// 		auto t = task(&request.execute, callback);
// 		pool.put(t);
// 	}

// 	int[Tid] progresses;
// 	size_t finished = 0;
// 	while (
// 		finished != requests.length) {
// 		receive(
// 			(LinkTerminated arg) {
// 			++finished;

// 			// Проверьте, не завершается ли этот поток преждевременно
// 			enforce((arg.tid in progresses) &&
// 				(progresses[arg.tid] == 100),
// 				format!"Thread %s exited unexpectedly"(arg.tid));
// 		},

// 			(Tid childTid, int progress) {
// 			progresses[childTid] = progress;
// 			display(progresses);
// 		}
// 		);
// 	}

// 	pool.finish();

// 	if (callback !is null)
// 		callback();
// }

void display(Progress[Tid] progresses) {
	import std.algorithm;

	const current = progresses.byValue.map!(p => p.current).sum;
	const total = progresses.byValue.map!(p => p.total).sum;
	int progress = cast(int)(100.0 * current / total);
	writefln("Downloading %d%%.", progress);
}
