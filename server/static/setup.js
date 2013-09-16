(function(namespace, undefined) {
    var global = this;

    namespace.config.host = global.test_host;

    namespace.util.append_script = function(src) {
        var div = document.getElementById("result");
        div.innerHTML = src;
    };
})(
    (function(global) {
        if (!global._app_namespace) global._app_namespace = {};
        if (!global._app_namespace.util) global._app_namespace.util = {};
        if (!global._app_namespace.config) global._app_namespace.config = {};
        return global._app_namespace;
    })(this)
);