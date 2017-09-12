#!/bin/bash -i

echo "Removing containers older then 8 hours"
docker container prune -f --filter "until=8h"
echo "Removing all images, except with the label of retention=keep"
docker image prune -a -f --filter "label!=retention=keep"
