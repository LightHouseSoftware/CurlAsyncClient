module listener;

import std.stdio;

interface EventListener {
}

class ProgressListener : EventListener {

    private int _progress;

    public void watch(size_t total, size_t current) {
        int progress = cast(int)(100.0 * current / total);
        if (_progress < progress) {
            _progress = progress;
            synchronized writefln("Downloading %d%%.", _progress);
        }
    }
}

class MultifileProgressListener : EventListener {
    import std.concurrency;

    private Tid _ownerTid;

    this(Tid ownerTid) {
        _ownerTid = ownerTid;
    }

    public void watch(size_t total, size_t current) {
        _ownerTid.send(thisTid, total, current);
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

    public void watch(ubyte[] data) {
        _file.rawWrite(data);
    }
}

class StatusListener : EventListener {

    public void watch(ushort code, string reason) {
        writefln("Status( code: %d, reason: %s )", code, reason);
    }
}
