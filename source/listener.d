module listener;

import std.stdio;

import entity;

interface EventListener {
}

class ProgressListener : EventListener {

    private int _progress;

    public void watch(size_t total, size_t current) {
        int progress = cast(int)(100.0 * current / total);
        if (_progress < progress) {
            _progress = progress;
            writefln("Downloading %d%%.", _progress);
        }
    }
}

class MultifileProgressListener : EventListener {
    import std.concurrency;

    private Progress[Tid] _progresses;

    public void watch(size_t total, size_t current) {
        _progresses[thisTid] = Progress(thisTid, total, current);
        display(_progresses);
    }

    private void display(Progress[Tid] progresses) {
        import std.algorithm;
        import std.stdio;

        const current = progresses.byValue.map!(p => p.current).sum;
        const total = progresses.byValue.map!(p => p.total).sum;
        int progress = cast(int)(100.0 * current / total);
        writefln("Downloading %d%%.", progress);
    }
}

class ResultListener : EventListener {

    public void watch(ubyte[] data) {
        writeln(cast(string) data);
    }
}

class SaveListener : EventListener {
    import std.path, std.stdio, std.file;

    private File _file;

    this(string path) {
        auto p = path
            .dirName
            .buildPath;
        p.mkdirRecurse;

        _file = File(path, "wb");
    }

    ~this() {
        if (_file.isOpen)
            _file.close;
    }

    public void watch(ubyte[] data) {
        _file.rawWrite(data);
    }
}

class StatusListener : EventListener {

    public void watch(ushort code, string reason) {
        writefln("Status( code: %d, reason: %s )", code, reason);
    }
}
