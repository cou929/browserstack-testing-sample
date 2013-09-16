module.exports = function(grunt) {
    "use strict";

    grunt.initConfig({
        concat: {
            "dist/test_sample.js": ["src/config.js", "src/util.js", "src/sample.js"]
        },
        jshint: {
            src: {
                src: [ "src/**/*.js" ]
            },
            dist: {
                src: [ "dist/*.js" ]
            },
            grunt: {
                src: [ "Gruntfile.js" ]
            },
            tests: {
                src: [ "server/static/**/*.js" ]
            }
        }
    });

    grunt.loadNpmTasks("grunt-contrib-concat");
    grunt.loadNpmTasks("grunt-contrib-jshint");

    grunt.registerTask( "default", [ "concat", "jshint" ] );
};
