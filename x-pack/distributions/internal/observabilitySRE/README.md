# ObservabilitySRE container DEV guide

This is a top level guide for working on the ObservabiltySRE container locally. 

## Building the image

You can use the gradle task in the top level of the logstash dir. This will build an image based on your local checkout. 

```
./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true
```

## Smoke tests

The smoke tests are designed run against an image you have built locally. You can run the smoke tests with the helper in the `ci` dir. This sets the version of the ES fips image based on the logstash version. If you need to override that you can set the environment variables (see the script for details). 

```
./ci/observabilitySREsmoke_tests.sh
```

## Acceptance tests

The acceptance tests are meant to run against an image that has been published to the elastic container repository. You can run the acceptance tests with the helper in the `ci` dir. This sets the version of the ES fips image based on the logstash version. If you need to override that you can set the environment variables (see the script for details). 

```
./ci/observabilitySREacceptance_tests.sh
```