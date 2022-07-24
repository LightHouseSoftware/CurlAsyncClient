module entity;

import std.concurrency;

alias Callback = void delegate();

struct HttpHeader {
    string name;
    string value;

    this(string name, string value) {
        this.name = name;
        this.value = value;
    }
}

struct Artifact {
    string url;
    string path;
}

struct Progress {
    import std.concurrency;

    size_t total;
    size_t current;
}
