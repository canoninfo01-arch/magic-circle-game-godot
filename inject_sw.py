with open("build/index.html", "r") as f:
    html = f.read()
script = (
    '<script>'
    'if (!window.crossOriginIsolated && "serviceWorker" in navigator) {'
    '  navigator.serviceWorker.addEventListener("controllerchange", function() {'
    '    location.reload();'
    '  });'
    '  navigator.serviceWorker.register("coi-sw.js");'
    '}'
    '</script>'
)
html = html.replace("</head>", script + "</head>", 1)
with open("build/index.html", "w") as f:
    f.write(html)
print("Injection OK, coi-sw count:", html.count("coi-sw"))
