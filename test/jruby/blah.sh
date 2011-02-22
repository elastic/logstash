[ -z "$1" ] && set -- 3000
ulimit -c unlimited
(sleep 5; seq -f "Feb 21 19:38:11 snack foo: hello world %g" $1 ; sleep 10) \
  | exec -a "logstash" jruby -J-server -J-Xmx20m -J-verbose:gc ../../bin/logstash -f simple.conf -v
