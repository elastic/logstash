basedir=$(cd `dirname $0`/..; pwd)

setup_ruby() {
  export RUBYLIB="${basedir}/lib"

  # Verify ruby works
  if ! ruby -e 'puts "HURRAY"' 2> /dev/null | grep -q "HURRAY" ; then
    echo "No ruby program found. Cannot start."
    exit 1
  fi

  # set $RUBY and $RUBYVER
  eval $(ruby -rrbconfig -e 'puts "RUBYVER=#{RbConfig::CONFIG["ruby_version"]}"; puts "RUBY=#{RUBY_ENGINE}"')

  LAUNCHCMD="ruby"
  LAUNCHARGS=()

  export GEM_HOME="${basedir}/vendor/bundle/${RUBY}/${RUBYVER}"
  export GEM_PATH=
}

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

  if [ "$(basename $JAVACMD)" = "drip" ] ; then
    export DRIP_INIT_CLASS="org.jruby.main.DripMain"
    export DRIP_INIT=
  fi

  JAVA_OPTS_ARGS=()
  JAVA_OPTS_ARGS+=("-Xmx${LS_HEAP_SIZE}")

  JAVA_OPTS_ARGS+=("-XX:+UseParNewGC")
  JAVA_OPTS_ARGS+=("-XX:+UseConcMarkSweepGC")
  JAVA_OPTS_ARGS+=("-Djava.awt.headless=true")

  JAVA_OPTS_ARGS+=("-XX:CMSInitiatingOccupancyFraction=75")
  JAVA_OPTS_ARGS+=("-XX:+UseCMSInitiatingOccupancyOnly")

  if [ ! -z "$LS_USE_GC_LOGGING" ] ; then
    JAVA_OPTS_ARGS+=("-XX:+PrintGCDetails")
    JAVA_OPTS_ARGS+=("-XX:+PrintGCTimeStamps")
    JAVA_OPTS_ARGS+=("-XX:+PrintClassHistogram")
    JAVA_OPTS_ARGS+=("-XX:+PrintTenuringDistribution")
    JAVA_OPTS_ARGS+=("-XX:+PrintGCApplicationStoppedTime")
    JAVA_OPTS_ARGS+=("-Xloggc:./logstash-gc.log")
    echo "Writing garbage collection logs to ./logstash-gc.log"
  fi

  export JAVACMD
  export JAVA_OPTS="${JAVA_OPTS_ARGS[@]}"
}

setup_vendored_jruby() {
  RUBYVER=1.9
  RUBY=jruby

  LAUNCHCMD="${JAVACMD}"
  LAUNCHARGS=("${JAVA_OPTS_ARGS[@]}")
  LAUNCHARGS+=("-jar")
  LAUNCHARGS+=("${basedir}"/vendor/jar/jruby-complete-*.jar)

  export RUBYLIB="${basedir}/lib"
  export GEM_HOME="${basedir}/vendor/bundle/${RUBY}/${RUBYVER}"
  export GEM_PATH=
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
    LAUNCHARGS+=("${basedir}/gembag.rb")
    LAUNCHARGS+=("${basedir}/logstash.gemspec")
    exec "$LAUNCHCMD" "${LAUNCHARGS[@]}"
  else
    echo "Cannot install dependencies; missing logstash.gemspec. This 'deps' command only works from a logstash git clone."
  fi
}
