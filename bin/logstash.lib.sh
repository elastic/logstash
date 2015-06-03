unset CDPATH
LOGSTASH_HOME=$(cd `dirname $0`/..; pwd)
export LOGSTASH_HOME

# Defaults you can override with environment variables
LS_HEAP_SIZE="${LS_HEAP_SIZE:=500m}"

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
    echo "Could not find any executable java binary. Please install java in your PATH or set JAVA_HOME." 1>&2
    exit 1
  fi

  if [ "$JAVA_OPTS" ] ; then
    echo "WARNING: Default JAVA_OPTS will be overridden by the JAVA_OPTS defined in the environment. Environment JAVA_OPTS are $JAVA_OPTS"  1>&2
  else
    # There are no JAVA_OPTS set from the client, we set a predefined
    # set of options that think are good in general
    JAVA_OPTS="-XX:+UseParNewGC"
    JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC"
    JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"

    JAVA_OPTS="$JAVA_OPTS -XX:CMSInitiatingOccupancyFraction=75"
    JAVA_OPTS="$JAVA_OPTS -XX:+UseCMSInitiatingOccupancyOnly"
  fi

  if [ "$LS_JAVA_OPTS" ] ; then
    # The client set the variable LS_JAVA_OPTS, choosing his own
    # set of java opts.
    JAVA_OPTS="$JAVA_OPTS $LS_JAVA_OPTS"
  fi

  if [ "$LS_HEAP_SIZE" ] ; then
    JAVA_OPTS="$JAVA_OPTS -Xmx${LS_HEAP_SIZE}"
  fi

  if [ "$LS_USE_GC_LOGGING" ] ; then
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
  if [ -z "$DRIP_JAVACMD" ] ; then
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
    export JRUBY_OPTS="$JRUBY_OPTS -J-XX:+TieredCompilation -J-XX:TieredStopAtLevel=1 -J-noverify"
  else
    JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -noverify"
  fi
  export JAVACMD
  export DRIP_INIT_CLASS="org.jruby.main.DripMain"
  export DRIP_INIT=""
}

setup_vendored_jruby() {
  JRUBY_BIN="${LOGSTASH_HOME}/vendor/jruby/bin/jruby"

  if [ ! -f "${JRUBY_BIN}" ] ; then
    echo "Unable to find JRuby."
    echo "If you are a user, this is a bug."
    echo "If you are a developer, please run 'rake bootstrap'. Running 'rake' requires the 'ruby' program be available."
    exit 1
  fi
  VENDORED_JRUBY=1
}

setup_ruby() {
  RUBYCMD="ruby"
  VENDORED_JRUBY=
}

jruby_opts() {
  printf "%s" "--1.9"
  for i in $JAVA_OPTS ; do
    printf "%s" " -J$i"
  done
}

setup() {
  # first check if we want to use drip, which can be used in vendored jruby mode
  # and also when setting USE_RUBY=1 if the ruby interpretor is in fact jruby
  if [ "$JAVACMD" ] ; then
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
}

ruby_exec() {
  if [ -z "$VENDORED_JRUBY" ] ; then

    # $VENDORED_JRUBY is empty so use the local "ruby" command

    if [ "$DEBUG" ] ; then
      echo "DEBUG: exec ${RUBYCMD} $@"
    fi
    exec "${RUBYCMD}" "$@"
  else

    # $VENDORED_JRUBY is non-empty so use the vendored JRuby

    if [ "$DEBUG" ] ; then
      echo "DEBUG: exec ${JRUBY_BIN} $(jruby_opts) $@"
    fi
    exec "${JRUBY_BIN}" $(jruby_opts) "$@"
  fi
}
