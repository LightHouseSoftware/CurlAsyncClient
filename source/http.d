module http;

import std.net.curl : HTTP, CurlException, HTTPStatusException;
import std.signals;
import std.json;

import entity;
import listener;

class Request {
    private {
        HTTP _client;
        Callback _callback;
    }

    this(string url) {
        this(url, HTTP.Method.get, JSONValue());
    }

    this(string url, JSONValue postBody) {
        this(url, HTTP.Method.post, postBody);
    }

    this(string url, HTTP.Method method, JSONValue postBody) {
        import std.range;

        _client = HTTP();
        _client.method(method);
        _client.url = url;

        if (method == HTTP.Method.post) {
            (postBody.isNull)
                ? _client.postData("") : _client.setPostData(postBody.toString, "application/json; charset=utf-8");
        }

        _client.onReceiveStatusLine = (HTTP.StatusLine stat) {
            emit(stat.code, stat.reason);
        };

        _client.onProgress = (size_t dltotal, size_t dlnow, size_t ultotal, size_t ulnow) {
            if (dltotal != 0) {
                emit(dltotal, dlnow);
            }
            return 0;
        };

        _client.onReceive = (ubyte[] data) { emit(data); return data.length; };
    }

    ~this() {
        _client.shutdown;
        destroy(this);
    }

    public void execute(Callback callback = null) {

        import std.parallelism;

        auto t = task(() {
            _client.perform();
            if (callback !is null)
                callback();
        });
        t.executeInNewThread();

    }

    public void addEventListener(T : EventListener)(T listener) {
        connect(&listener.watch);
    }

    public void setAuth(string token) {
        addHeader(HttpHeader("Authorization", "Bearer " ~ token));
    }

    public void addHeader(HttpHeader header) {
        _client.addRequestHeader(header.name, header.value);
    }

    mixin Signal!(ushort, string);
    mixin Signal!(size_t, size_t);
    mixin Signal!(ubyte[]);
}
