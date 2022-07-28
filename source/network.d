module network;

import std.net.curl : HTTP;

import entity;
import listener;

class Network {

    public static HttpConn conn(T : EventListener)(Request request, T[] listener...) {

        HttpConn conn = conn(request);

        foreach (l; listener) {
            conn.addEventListener(l);
        }

        return conn;
    }

    public static HttpConn conn(Request request) {

        import std.net.curl;

        HttpConn conn = new HttpConn();
        conn.url(request.url);
        conn.method(request.method);

        if (request.method == HTTP.Method.post) {
            (request.postBody.isNull)
                ? conn.postData("") : conn.setPostData(request.postBody.toString, "application/json; charset=utf-8");
        }

        return conn;
    }

    public static string getAsText(HttpConn conn, Request request) {
        import std.net.curl;

        return cast(string) get(request.url, conn.client);
    }

    public static HttpConn download(Request request) {
        return Network.conn(request, new SaveListener(request.path));
    }

    public static void multiDownload(T : EventListener)(Request[] requests, T listener = null,
        Callback callback = null, string accessToken = null, HttpHeader[] headers = null) {
        foreach (Request req; requests.parallel) {
            HttpConn conn = Network.download(req);
            if (accessToken !is null)
                conn.setAuth(accessToken);
            if (headers !is null) {
                foreach (header; headers) {
                    conn.addHeader(header);
                }
            }
            if (listener !is null)
                conn.addEventListener(listener);
            conn.execute;
        }

        if (callback !is null)
            callback();
    }
}
