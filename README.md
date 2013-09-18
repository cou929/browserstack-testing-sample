# Sample of BrowserStack Testing

    cp config_test.yaml.sample config_test.yaml
    vim config_test.yaml   # set your user name and access key
    carton install
    carton exec -I lib "TEST_HOME=. prove -PTest::BrowserStack t/"
