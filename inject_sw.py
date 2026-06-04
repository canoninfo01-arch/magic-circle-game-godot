with open("build/index.html", "r") as f:
    html = f.read()
script = (
    '<script>'
    'if (!window.crossOriginIsolated && "serviceWorker" in navigator) {'
    '  navigator.serviceWorker.register("coi-sw.js").then(function(r) {'
    '    if (r.installing) {'
    '      navigator.serviceWorker.addEventListener("controllerchange", function() {'
    '        location.reload();'
    '      });'
    '    }'
    '  });'
    '}'
    '</script>'
)
html = html.replace("</head>", script + "</head>", 1)
with open("build/index.html", "w") as f:
    f.write(html)
print("Injection OK, coi-sw count:", html.count("coi-sw"))
