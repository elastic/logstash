unset CDPATH
# This unwieldy bit of scripting is to try to catch instances where Logstash
# was launched from a symlink, rather than a full path to the Logstash binary
if [ -L $0 ]; then
  # Launched from a symlink
  # --Test for the readlink binary
  RL=$(which readlink)
  if [ $? -eq 0 ]; then
    # readlink exists
    SOURCEPATH=$($RL $0)
  else
    # readlink not found, attempt to parse the output of stat
    SOURCEPATH=$(stat -c %N $0 | awk '{print $3}' | sed -e 's/\‘//' -e 's/\’//')
    if [ $? -ne 0 ]; then
      # Failed to execute or parse stat
      echo "Failed to set LOGSTASH_HOME from $(cd `dirname $0`/..; pwd)/bin/logstash.lib.sh"
      echo "You may need to launch Logstash with a full path instead of a symlink."
      exit 1
    fi
  fi
else
  # Not a symlink
  SOURCEPATH=$0
fi

LOGSTASH_HOME=$(cd `dirname $SOURCEPATH`/..; pwd)
export LOGSTASH_HOME

parse_jvm_options() {
  if [ -f "$1" ]; then
    echo "$(grep "^-" "$1" | tr '\n' ' ')"
  fi
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
    echo "Could not find any executable java binary. Please install java in your PATH or set JAVA_HOME." 1>&2
    exit 1
  fi

  if [ "$JAVA_OPTS" ] ; then
    echo "WARNING: Default JAVA_OPTS will be overridden by the JAVA_OPTS defined in the environment. Environment JAVA_OPTS are $JAVA_OPTS"  1>&2
  fi

  # Set a default GC log file for use by jvm.options _before_ it's called.
  if [ -z "$LS_GC_LOG_FILE" ] ; then
    LS_GC_LOG_FILE="./logstash-gc.log"
  fi

  # Set the initial JVM options from the jvm.options file.  Look in
  # /etc/logstash first, and break if that file is found readable there.
  if [ -z "$LS_JVM_OPTS" ]; then
      for jvm_options in /etc/logstash/jvm.options \
                        "$LOGSTASH_HOME"/config/jvm.options;
                         do
          if [ -r "$jvm_options" ]; then
              LS_JVM_OPTS=$jvm_options
              break
          fi
      done
  fi
  # use the defaults, first, then override with anything provided
  LS_JAVA_OPTS="$(parse_jvm_options "$LS_JVM_OPTS") $LS_JAVA_OPTS"

  if [ "$LS_JAVA_OPTS" ] ; then
    # The client set the variable LS_JAVA_OPTS, choosing his own
    # set of java opts.
    JAVA_OPTS="$JAVA_OPTS $LS_JAVA_OPTS"
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
    if [ -z "$i" ]; then
      printf "%s" " -J$i"
    fi
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
