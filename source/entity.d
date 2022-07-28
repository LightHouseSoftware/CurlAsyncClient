module entity;

alias Callback = void delegate();

class HttpConn {
    import std.net.curl : HTTP;
    import std.signals;

    import listener;

    HTTP client;
    alias client this;

    this() {
        client = HTTP();

        client.onReceiveStatusLine = (HTTP.StatusLine stat) {
            emit(stat.code, stat.reason);
        };

        client.onProgress = (size_t dltotal, size_t dlnow, size_t ultotal, size_t ulnow) {
            if (dltotal != 0) {
                emit(dltotal, dlnow);
            }
            return 0;
        };

        client.onReceive = (ubyte[] data) { emit(data); return data.length; };
    }

    ~this() {
        if (!client.isStopped)
            client.shutdown;
    }

    public void execute() {
        client.perform();
    }

    public void execute(Callback callback) {
        client.perform();
        callback();
    }

    public void executeInNewThread() {
        import std.parallelism;

        task((HttpConn conn) { client.perform(); }, this).executeInNewThread;
    }

    public void executeInNewThread(Callback callback) {
        import std.parallelism;

        task((HttpConn conn, Callback callback) { client.perform(); callback(); }, this, callback)
            .executeInNewThread;
    }

    public void setAuth(string token) {
        addHeader(HttpHeader("Authorization", "Bearer " ~ token));
    }

    public void addHeader(HttpHeader header) {
        client.addRequestHeader(header.name, header.value);
    }

    public void addEventListener(T : EventListener)(T listener) {
        connect(&listener.watch);
    }

    mixin Signal!(ushort, string);
    mixin Signal!(size_t, size_t);
    mixin Signal!(ubyte[]);
}

struct HttpHeader {
    string name;
    string value;

    this(string name, string value) {
        this.name = name;
        this.value = value;
    }
}

struct Request {
    string url;

    import std.net.curl : HTTP;

    HTTP.Method method;
    string path;

    import std.json;

    JSONValue postBody;
}

struct Progress {
    size_t total;
    size_t current;
}
