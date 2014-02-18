

logstash=$HOME/projects/logstash
contrib=$HOME/projects/logstash-contrib

workdir="$PWD/build/release/"
mkdir -p $workdir

# circuit breaker to fail if there's something silly wrong.
if [ -z "$workdir" ] ; then
  echo "workdir is empty?!"
  exit 1
fi

if [ ! -d "$contrib" ] ; then
  echo "Missing: $contrib"
  echo "Maybe git clone it?"
  exit 1
fi

set -e

prepare() {
  rsync -a --delete $logstash/{bin,docs,lib,spec,Makefile,gembag.rb,logstash.gemspec,tools,locales,patterns,LICENSE,README.md} $contrib/{lib,spec} $workdir
  rm -f $logstash/.VERSION.mk
  make -C $logstash .VERSION.mk
  cp $logstash/.VERSION.mk $workdir
}

docs() {
  make -C $workdir build
  (cd $contrib; find lib/logstash -type f -name '*.rb') > $workdir/build/contrib_plugins
  make -C $workdir -j 4 docs
}

tests() {
  make -C $workdir test
  make -C $workdir tarball test
}

packages() {
  for path in $logstash $contrib ; do
    rm -f $path/build/*.tar.gz
    rm -f $path/build/*.zip
    echo "Building packages: $path"
    make -C $path tarball package
    (cd $path/build; cp *.gz *.rpm *.deb *.zip $workdir/build)
  done
}

prepare
tests
docs
packages
