#!/bin/bash

ES_HOME=${WORKDIR}/elasticsearch

# Set "http.host" to make the service visible from outside the container.
${ES_HOME}/bin/elasticsearch -E http.host=0.0.0.0
