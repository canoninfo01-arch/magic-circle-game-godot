self.addEventListener("install", function() { self.skipWaiting(); });
self.addEventListener("activate", function(e) { e.waitUntil(self.clients.claim()); });
self.addEventListener("fetch", function(e) {
  if (e.request.cache === "only-if-cached" && e.request.mode !== "same-origin") return;
  e.respondWith(fetch(e.request).then(function(r) {
    if (r.status === 0) return r;
    var h = new Headers(r.headers);
    h.set("Cross-Origin-Opener-Policy", "same-origin");
    h.set("Cross-Origin-Embedder-Policy", "require-corp");
    return new Response(r.body, {status: r.status, statusText: r.statusText, headers: h});
  }));
});
