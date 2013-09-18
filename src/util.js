(function(namespace, undefined) {
    'use strict';

    _export(namespace, 'is_valid_url', is_valid_url);
    _export(namespace, 'append_script', append_script);

    function is_valid_url(url) {
        var re = /^http/;
        return re.test(url);
    }

    function append_script(src) {
        var el = document.createElement('script');
        el.type = 'text/javascript';
        el.async = true;
        el.src = src;
        var s = document.getElementsByTagName('script')[0];
        _wait_dom_ready(function() {
            s.parentNode.insertBefore(el, s);
        });
    }

    function _wait_dom_ready(callback) {
        var is_loaded = false;

        if (document.readyState === 'complete' || document.readyState === 'loaded') {
            callback();
            return;
        }

        if (document.addEventListener){
            document.addEventListener('DOMContentLoaded',function(){
                callback();
                is_loaded = true;
            }, false);
            window.addEventListener('load', function(){
                if (!is_loaded) callback();
            }, false);
        } else if (window.attachEvent) {
            if (window.ActiveXObject && window === window.top) {
                _ie();
            } else {
                window.attachEvent('onload', callback);
            }
        } else {
            var _onload = window.onload;
            window.onload = function(){
                if (typeof _onload === 'function') {
                    _onload();
                }
                callback();
            };
        }

        function _ie(){
            try {
                document.documentElement.doScroll('left');
            } catch (e) {
                setTimeout(_ie, 0);
                return;
            }
            callback();
        }
    }

    function _export(ns, key, value) {
        if (!ns[key]) {
            ns[key] = value;
        }
    }
})(
    (function(global) {
        if (!global._app_namespace) global._app_namespace = {};
        if (!global._app_namespace.util) global._app_namespace.util = {};
        return global._app_namespace.util;
    })(this)
);