#!/usr/bin/env bash

##
# Installing rbenv
##

git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
type rbenv

git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

##
# install jruby-1.7.24 and make it global
##

rbenv install jruby-1.7.24
rbenv global  jruby-1.7.24


##
# install logstash from source code
##

git clone https://github.com/elastic/logstash.git
