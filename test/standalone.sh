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
git pull origin master
git checkout master

ruby="ruby-1.8.7"
gemset="logstash-testing"

if ! rvm list | grep "$ruby" ; then
  rvm install "$ruby"
fi

rm -f *.gem
rvm gemset create $gemset
rvm "$ruby@$gemset" gem uninstall -ax logstash || true
rvm "$ruby@$gemset" gem build logstash.gemspec
rvm "$ruby@$gemset" gem install --no-ri --no-rdoc logstash-*.gem

# stompserver says it wants 'hoe >= 1.1.1' and the latest 'hoe' requires
# some bullshit version of rubygems that nobody will have, so install
# an older one.
rvm "$ruby@$gemset" gem update --system
rvm "$ruby@$gemset" gem install --no-ri --no-rdoc stompserver

echo "Running tests now..."
rvm "$ruby@$gemset" exec logstash-test

