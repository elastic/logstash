#!/usr/bin/env bash

##
# Installing rbenv
##
git clone git://github.com/sstephenson/rbenv.git .rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile


##
# install logstash from source code
##
git clone https://github.com/elastic/logstash.git

##
# install jruby-1.7.24 and make it global
##
rbenv install jruby-1.7.24
rbenv global  jruby-1.7.24

cd logstash
rake bootstrap
rake test:install-core
