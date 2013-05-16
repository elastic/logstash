#!/bin/bash


VERSION="$(awk -F\" '/LOGSTASH_VERSION/ {print $2}' $(dirname $0)/../lib/logstash/version.rb)"

if [ "$#" -ne 2 ] ; then
  echo "Usage: $0 <os> <release>"
  echo 
  echo "Example: $0 ubuntu 12.10"
  exit 1
fi

os=$1
release=$2

echo "Building package for $os $release"

destdir=build/
prefix=/opt/logstash

if [ "$destdir/$prefix" != "/" -a -d "$destdir/$prefix" ] ; then
  rm -rf "$destdir/$prefix"
fi

mkdir -p $destdir/$prefix


# install logstash.jar
jar="$(dirname $0)/../build/logstash-$VERSION-flatjar.jar" 
if [ ! -f "$jar" ] ; then
  echo "Unable to find $jar"
  exit 1
fi

cp $jar $destdir/$prefix/logstash.jar

case $os@$release in
  centos@*)
    mkdir -p $destdir/etc/logrotate.d
    mkdir -p $destdir/etc/sysconfig
    mkdir -p $destdir/etc/init.d
	mkdir -p $destdir/etc/logstash/conf.d
	mkdir -p $destdir/opt/logstash
    mkdir -p $destdir/var/lib/logstash
    mkdir -p $destdir/var/run/logstash
    mkdir -p $destdir/var/log/logstash
    cp $os/sysconfig $destdir/etc/sysconfig/logstash
    install -m644 logrotate.conf $destdir/etc/logrotate.d/
    install -m755 logstash.sysv.redhat $destdir/etc/init.d/logstash
    ;;
  ubuntu@*)
    mkdir -p $destdir/etc/logrotate.d
    mkdir -p $destdir/etc/init
    mkdir -p $destdir/var/log/logstash
    touch $destdir/etc/sysconfig/logstash
    install -m644 logrotate.conf $destdir/etc/logrotate.d/
    install -m755 logstash.upstart.ubuntu $destdir/etc/init/logstash.conf
    ;;
  debian@*)
    mkdir -p $destdir/etc/logrotate.d
    mkdir -p $destdir/etc/init.d
    mkdir -p $destdir/var/lib/logstash
    mkdir -p $destdir/var/run/logstash
    mkdir -p $destdir/var/log/logstash
    install -m644 logrotate.conf $destdir/etc/logrotate.d/
    install -m755 logstash.sysv.debian $destdir/etc/init.d/logstash
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
      -a noarch --iteration 1_$os \
      -d "jre >= 1.6.0" \
      --before-install centos/before-install.sh \
      --before-remove centos/before-remove.sh \
      --after-install centos/after-install.sh \
      -f -C $destdir .
    ;;
  ubuntu|debian) 
    fpm -s dir -t deb -n logstash -v "$VERSION" \
      -a all --iteration 1-$os \
      -d "java6-runtime" \
      --before-install ubuntu/before-install.sh \
      --before-remove ubuntu/before-remove.sh \
      --after-install ubuntu/after-install.sh \
      -f -C $destdir .
    ;;
esac
