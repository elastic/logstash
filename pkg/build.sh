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

destdir=build/$(echo "$os" | tr ' ' '_')
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
    mkdir -p $destdir/opt/logstash/tmp
    mkdir -p $destdir/var/lib/logstash
    mkdir -p $destdir/var/run/logstash
    mkdir -p $destdir/var/log/logstash
    cp $os/sysconfig $destdir/etc/sysconfig/logstash
    install -m644 logrotate.conf $destdir/etc/logrotate.d/
    install -m755 logstash.sysv.redhat $destdir/etc/init.d/logstash
    ;;
  ubuntu@*)
    mkdir -p $destdir/etc/logstash/conf.d
    mkdir -p $destdir/etc/logrotate.d
    mkdir -p $destdir/etc/init
    mkdir -p $destdir/var/lib/logstash
    mkdir -p $destdir/var/log/logstash
    mkdir -p $destdir/etc/default
    touch $destdir/etc/default/logstash
    install -m644 logrotate.conf $destdir/etc/logrotate.d/logstash
    install -m644 logstash.default $destdir/etc/default/logstash
    install -m644 logstash-web.default $destdir/etc/default/logstash-web
    install -m755 logstash.upstart.ubuntu $destdir/etc/init/logstash.conf
    install -m755 logstash-web.upstart.ubuntu $destdir/etc/init/logstash-web.conf
    ;;
  debian@*)
    mkdir -p $destdir/etc/logstash/conf.d
    mkdir -p $destdir/etc/logrotate.d
    mkdir -p $destdir/etc/init.d
    mkdir -p $destdir/var/lib/logstash
    mkdir -p $destdir/var/log/logstash
    mkdir -p $destdir/etc/default
    touch $destdir/etc/default/logstash
    install -m644 logrotate.conf $destdir/etc/logrotate.d/logstash
    install -m644 logstash.default $destdir/etc/default/logstash
    install -m644 logstash-web.default $destdir/etc/default/logstash-web
    install -m755 logstash.sysv.debian $destdir/etc/init.d/logstash
    install -m755 logstash-web.sysv.debian $destdir/etc/init.d/logstash-web
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
    if ! echo $VERSION | grep -q '\.(dev\|rc.*)'; then
      # This is a dev or RC version... So change the upstream version
      # example: 1.2.2.dev => 1.2.2~dev
      # This ensures a clean upgrade path.
      VERSION="$(echo $VERSION | sed 's/\.\(dev\|rc.*\)/~\1/')"
    fi

    if ! git show-ref --tags | grep -q "$(git rev-parse HEAD)"; then
      # HEAD is not tagged, add the date, time and commit hash to the revision
      REVISION="+$(date -u +%Y%m%d%H%M)~$(git rev-parse --short HEAD)"
    fi

    fpm -s dir -t deb -n logstash -v "$VERSION" \
      -a all --iteration "${os}1${REVISION}" \
      --url "http://logstash.net" \
      --description "An extensible logging pipeline" \
      -d "default-jre" \
      --deb-user root --deb-group root \
      --before-install $os/before-install.sh \
      --before-remove $os/before-remove.sh \
      --after-install $os/after-install.sh \
      -f -C $destdir .
    ;;
esac
