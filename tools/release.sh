

logstash=$HOME/projects/logstash
contrib=$HOME/projects/logstash-contrib

workdir="/tmp/logstash-release"
mkdir $workdir

# circuit breaker to fail if there's something silly wrong.
if [ -z "$workdir" ] ; then
  echo "workdir is empty?!"
  exit 1
fi

set -e

docs() {
  rsync -av --delete $logstash/{docs,lib,spec,Makefile} $contrib/{lib,spec} $workdir
  rm -f $logstash/.VERSION.mk
  make -C $logstash .VERSION.mk
  cp $logstash/.VERSION.mk $workdir

  make -C $workdir build
  (cd $contrib; find lib/logstash -type f -name '*.rb') > $workdir/build/contrib_plugins
  make -C $workdir docs
}

packages() {
  for path in $logstash $contrib ; do
    rm -f $path/build/*.tar.gz
    rm -f $path/build/*.zip
    make -C $path tarball package
    (cd $path/build; cp *.gz *.rpm *.deb *.zip $workdir/build)
  done
}

docs
packages
