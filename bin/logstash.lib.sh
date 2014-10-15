basedir=$(cd `dirname $0`/..; pwd)

setup_java() {
  if [ -z "$JAVACMD" ] ; then
    if [ -n "$JAVA_HOME" ] ; then
      JAVACMD="$JAVA_HOME/bin/java"
    else
      JAVACMD="java"
    fi
  fi

  # Resolve full path to the java command.
  if [ ! -f "$JAVACMD" ] ; then
    JAVACMD=$(which $JAVACMD 2>/dev/null)
  fi

  if [ ! -x "$JAVACMD" ] ; then
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

  export JAVACMD
  export JAVA_OPTS
}

setup_drip() {
  if [ -z $DRIP_JAVACMD ] ; then
    JAVACMD="drip"
  fi

  # resolve full path to the drip command.
  if [ ! -f "$JAVACMD" ] ; then
    JAVACMD=$(which $JAVACMD 2>/dev/null)
  fi

  if [ ! -x "$JAVACMD" ] ; then
    echo "Could not find executable drip binary. Please install drip in your PATH"
    exit 1
  fi

  # faster JRuby startup options https://github.com/jruby/jruby/wiki/Improving-startup-time
  # since we are using drip to speed up, we may as well throw these in also
  if [ "$USE_RUBY" = "1" ] ; then
    export JRUBY_OPTS="-J-XX:+TieredCompilation -J-XX:TieredStopAtLevel=1 -J-noverify"
  else
    JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -noverify"
  fi
  export JAVACMD
  export DRIP_INIT_CLASS="org.jruby.main.DripMain"
  export DRIP_INIT=""
}

setup_vendored_jruby() {
  JRUBY_JAR=$(ls "${basedir}"/vendor/jar/jruby-complete-*.jar)
  VENDORED_JRUBY=1
}

setup_ruby() {
  RUBYCMD="ruby"
  VENDORED_JRUBY=
}

setup() {
  # first check if we want to use drip, which can be used in vendored jruby mode
  # and also when setting USE_RUBY=1 if the ruby interpretor is in fact jruby
  if [ ! -z "$JAVACMD" ] ; then
    if [ "$(basename $JAVACMD)" = "drip" ] ; then
      DRIP_JAVACMD=1
      USE_DRIP=1
    fi
  fi
  if [ "$USE_DRIP" = "1" ] ; then
    setup_drip
  fi

  if [ "$USE_RUBY" = "1" ] ; then
    setup_ruby
  else
    setup_java
    setup_vendored_jruby
  fi

  export RUBYLIB="${basedir}/lib"
}

install_deps() {
  if [ -f "$basedir/logstash.gemspec" ] ; then
    if [ -z "$VENDORED_JRUBY" ] ; then
      exec "${RUBYCMD}" "${basedir}/gembag.rb" "${basedir}/logstash.gemspec" "$@"
    else
      exec "${JAVACMD}" $JAVA_OPTS "-jar" "$JRUBY_JAR" "${basedir}/gembag.rb" "${basedir}/logstash.gemspec" "$@"
    fi
  else
    echo "Cannot install dependencies; missing logstash.gemspec. This 'deps' command only works from a logstash git clone."
  fi
}