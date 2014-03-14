

logstash=$PWD
contrib=$PWD/../logstash-contrib/

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
  make -C $logstash package
  (cd $contrib;
    sh pkg/build.sh ubuntu 12.04
    sh pkg/build.sh centos 6
  )
  make -C $contrib package
  cp $logstash/.VERSION.mk $workdir
  rm -f $workdir/build/pkg
  rm -f $workdir/build/*.{zip,rpm,gz,deb} || true
}

docs() {
  make -C $workdir build
  (cd $contrib; find lib/logstash -type f -name '*.rb') > $workdir/build/contrib_plugins
  make -C $workdir -j 4 docs
}

tests() {
  USE_JRUBY=1 make -C $logstash test QUIET=
  USE_JRUBY=1 make -C $logstash tarball test QUIET=
}

packages() {
  for path in $logstash $contrib ; do
    rm -f $path/build/*.tar.gz
    rm -f $path/build/*.zip
    echo "Building packages: $path"
    make -C $path tarball
    for dir in build pkg ; do
      [ ! -d "$path/$dir" ] && continue
      (cd $path/$dir;
        for i in *.gz *.rpm *.deb *.zip *.jar ; do
          [ ! -f "$i" ] && continue
          echo "Copying $path/$dir/$i"
          cp $path/$dir/$i $workdir/build
        done
      )
    done
  done
}

prepare
tests
docs
packages
