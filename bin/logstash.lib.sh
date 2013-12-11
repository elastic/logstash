basedir=$(cd `dirname $0`/..; pwd)

setup_ruby() {
  # Verify ruby works
  if ! ruby -e 'puts "HURRAY"' 2> /dev/null | grep -q "HURRAY" ; then
    echo "No ruby program found. Cannot start."
    exit 1
  fi

  eval $(ruby -rrbconfig -e 'puts "RUBYVER=#{RbConfig::CONFIG["ruby_version"]}"; puts "RUBY=#{RUBY_ENGINE}"')
  RUBYCMD="ruby"
}

setup_java() {
  if [ -z "$JAVA_HOME/bin/java" ] ; then
    JAVA="$JAVA_HOME/bin/java"
  else
    JAVA=$(which java)
  fi

  if [ ! -x "$JAVA" ] ; then
    echo "Could not find any executable java binary. Please install java in your PATH or set JAVA_HOME."
    exit 1
  fi


  JAVA_OPTS="$JAVA_OPTS -Xmx${LS_HEAP_SIZE}"
  JAVA_OPTS="$JAVA_OPTS -XX:+UseParNewGC"
  JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC"
  JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"

  JAVA_OPTS="$JAVA_OPTS -XX:CMSInitiatingOccupancyFraction=75"
  JAVA_OPTS="$JAVA_OPTS -XX:+UseCMSInitiatingOccupancyOnly"

  if [ ! -z "$LS_USE_GC_LOGGING" ] ; then
    JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCDetails"
    JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCTimeStamps"
    JAVA_OPTS="$JAVA_OPTS -XX:+PrintClassHistogram"
    JAVA_OPTS="$JAVA_OPTS -XX:+PrintTenuringDistribution"
    JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCApplicationStoppedTime"
    JAVA_OPTS="$JAVA_OPTS -Xloggc:./logstash-gc.log"
    echo "Writing garbage collection logs to ./logstash-gc.log"
  fi
} 

setup_vendored_jruby() {
  RUBYVER=1.9
  RUBY=jruby

  setup_java

  RUBYCMD="$JAVA $JAVA_OPTS -jar $basedir/vendor/jar/jruby-complete-*.jar"
}

setup() {
  if [ -z "$USE_JRUBY" -a \( -d "$basedir/.git" -o ! -z "$USE_RUBY" \) ] ; then
    setup_ruby
    if [ "$RUBY" = "jruby" ] ; then
      setup_java
      export JAVA_OPTS
    fi
  else
    setup_vendored_jruby
  fi
  export GEM_HOME="$basedir/vendor/bundle/${RUBY}/${RUBYVER}"
  export GEM_PATH=
  export RUBYLIB="$basedir/lib"
}

install_deps() {
  if [ -f "$basedir/logstash.gemspec" ] ; then
    program="$basedir/gembag.rb"
    set -- "$basedir/logstash.gemspec"
    exec $RUBYCMD "$basedir/gembag.rb" "$@"
  else
    echo "Cannot install dependencies; missing logstash.gemspec. This 'deps' command only works from a logstash git clone."
  fi
}
