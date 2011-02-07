#!/usr/bin/env bash
rvm="$HOME/.rvm/scripts/rvm"

if [ ! -f "$rvm" ] ; then
  echo "rvm not found? You should install it."
  exit 1
fi

#cat << RVMRC > $HOME/.rvmrc
#rvm_install_on_use_flag=1
#rvm_project_rvmrc=0
#rvm_gemset_create_on_use_flag=1
#RVMRC

. "$rvm"
rvm rvmrc trust logstash

if [ "$1" = "" ] ; then
  set -- "ruby-1.8.7"
fi

ruby="$1"
gemset="logstash-testing"

run() {
  echo "$@"
  "$@"
}

if ! run rvm list | grep "$ruby" ; then
  run rvm install "$ruby"
fi


rm -f *.gem
rvm gemset create $gemset
run rvm "$ruby@$gemset" gem uninstall -ax logstash || true
run rvm "$ruby@$gemset" gem build logstash.gemspec
run rvm "$ruby@$gemset" gem install --no-ri --no-rdoc logstash-*.gem

# stompserver says it wants 'hoe >= 1.1.1' and the latest 'hoe' requires
# rubygems >1.4, so, upgrade I guess... I hate ruby sometimes.
run rvm "$ruby@$gemset" gem update --system
run rvm "$ruby@$gemset" gem install --no-ri --no-rdoc stompserver

echo "Running tests now..."
run rvm "$ruby@$gemset" exec logstash-test

