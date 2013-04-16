#!/bin/bash

VERSION=1.1.9
os="centos"
release="6"

destdir=build/
prefix=/opt/logstash

if [ "$destdir/$prefix" != "/" -a -d "$destdir/$prefix" ] ; then
  rm -rf "$destdir/$prefix"
fi

mkdir -p $destdir/$prefix

# install logstash.jar
cp $(dirname $0)/../build/logstash-$VERSION-monolithic.jar $destdir/$prefix

case $os@$release in
  centos@*)
    mkdir -p $destdir/etc/logrotate.d
    mkdir -p $destdir/etc/sysconfig
    mkdir -p $destdir/etc/init.d
    mkdir -p $destdir/var/lib/logstash
    mkdir -p $destdir/var/run/logstash
    mkdir -p $destdir/var/log/logstash
    touch $destdir/etc/sysconfig/logstash
    install -m644 logrotate.conf $destdir/etc/logrotate.d/
    install -m755 logstash.sysv.redhat $destdir/etc/init.d/logstash
    ;;
  *) 
    echo "Unknown OS: $os $release"
    exit 1
    ;;
esac

description="logstash is a system for managing and processing events and logs"
case $os in
  centos|fedora|redhat) 
    fpm -s dir -t rpm -n logstash -v "$VERSION" \
      -a noarch \
      --iteration 1 \
      -d "jre >= 1.6.0" \
      -C $destdir .
    ;;
  debian|ubuntu) 
    fpm -s dir -t deb -n logstash -v "$VERSION" \
      -a noarch \
      --iteration 1 \
      -d "java6-runtime" \
      -C $destdir .
    ;;
esac
