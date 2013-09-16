(function(namespace, undefined) {
    'use strict';

    _export(namespace, 'host', 'sample.production.com');
    _export(namespace, 'path', '/widget.js');

    function _export(ns, key, value) {
        if (!ns[key]) {
            ns[key] = value;
        }
    }
})(
    (function(global) {
        if (!global._app_namespace) global._app_namespace = {};
        if (!global._app_namespace.config) global._app_namespace.config = {};
        return global._app_namespace.config;
    })(this)
);
