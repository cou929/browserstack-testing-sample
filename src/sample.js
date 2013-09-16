(function(undefined) {
    'use strict';

    if (!window._app_namespace) window._app_namespace = {};
    var namespace = window._app_namespace;
    var util = namespace.util || false;
    var conf = namespace.config || false;
    if (!util) return;
    if (!conf) return;

    var url = window.location.href,
        type = namespace.type,
        status = namespace.status,
        host = conf.host,
        path = conf.path,
        protocol = ('https:' == document.location.protocol) ? 'https://' : 'http://';

    if (!util.is_valid_url(url)) return;

    var queries = [
        'url=' + encodeURIComponent(url),
        'type=' + encodeURIComponent(type),
        'status=' + encodeURIComponent(status)
    ];

    var src = protocol + host + path + '?' + queries.join('&');
    util.append_script(src);
})();
