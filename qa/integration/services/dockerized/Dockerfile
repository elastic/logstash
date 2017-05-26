FROM debian:stretch
##
# Define a base image for all service images.
##

ENV _JAVA_OPTIONS "-Djava.net.preferIPv4Stack=true"
ENV TERM=linux

RUN apt-get update && apt-get install -y curl openjdk-8-jre-headless netcat

RUN adduser --disabled-password --gecos '' tester
USER tester

# Define the work directory. Use this variable in derivated images and
# shell scripts.
ENV WORKDIR /home/tester
WORKDIR $WORKDIR

# Script with routines that can be used in derived images.
ADD helpers.sh .

# Expect this script in the context directory of a derived image. It should
# contain the service setup instructions, and is going to be the first executed
# command when a derived image is built.
ONBUILD ADD setup.sh .
ONBUILD RUN ./setup.sh

# Expect this script in the context directory of a derived image. It should
# contain the service start up instructions, and is going to be executed when
# a container is started.
ONBUILD ADD run.sh .
CMD ["./run.sh"]
