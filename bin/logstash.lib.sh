basedir=$(cd `dirname $0`/..; pwd)

setup_ruby() {
  export RUBYLIB="$basedir/lib"
  # Verify ruby works
  if ! ruby -e 'puts "HURRAY"' 2> /dev/null | grep -q "HURRAY" ; then
    echo "No ruby program found. Cannot start."
    exit 1
  fi

  eval $(ruby -rrbconfig -e 'puts "RUBYVER=#{RbConfig::CONFIG["ruby_version"]}"; puts "RUBY=#{RUBY_ENGINE}"')
  RUBYCMD="ruby"
  export GEM_HOME="$basedir/vendor/bundle/${RUBY}/${RUBYVER}"
  export GEM_PATH=
}

setup_java() {
  if [ -z "$JAVACMD" ] ; then
    if [ -z "$JAVA_HOME/bin/java" ] ; then
      JAVACMD="$JAVA_HOME/bin/java"
    else
      JAVACMD="java"
    fi
  elif [ "$(basename $JAVACMD)" = "drip" ] ; then
    export DRIP_INIT_CLASS="org.jruby.main.DripMain"
    export DRIP_INIT=
  fi

  if [ ! -x "$JAVACMD" ] ; then
    JAVACMD="$(which $JAVACMD 2> /dev/null)"
    if [ ! -x "$JAVACMD" ] ; then
      echo "Could not find any executable java binary (tried '$JAVACMD'). Please install java in your PATH or set JAVA_HOME."
      exit 1
    fi
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

  export JAVACMD
  export JAVA_OPTS
  export RUBYLIB="$basedir/lib"
  export GEM_HOME="$basedir/vendor/bundle/jruby/1.9"
  export GEM_PATH=
}

setup_vendored_jruby() {
  RUBYVER=1.9
  RUBY=jruby
  RUBYCMD="$JAVACMD $JAVA_OPTS -jar $basedir/vendor/jar/jruby-complete-*.jar"
}

setup() {
  setup_java
  if [ -z "$USE_JRUBY" -a \( -d "$basedir/.git" -o ! -z "$USE_RUBY" \) ] ; then
    setup_ruby
  else
    setup_vendored_jruby
  fi
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
