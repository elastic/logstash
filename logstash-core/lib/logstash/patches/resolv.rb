require "resolv"

# ref: https://github.com/logstash-plugins/logstash-filter-dns/issues/40
#
# JRuby 9k versions prior to 9.1.16.0 have a bug which crashes IP address
# resolution after 64k unique IP addresses resolutions.
#
# Note that the oldest JRuby version in LS 6 is 9.1.13.0 and
# JRuby 1.7.25 and 1.7.27 (the 2 versions used across LS 5) are not affected by this bug.

# make sure we abort if a known correct JRuby version is installed 
# to avoid having an unnecessary legacy patch being applied in the future.

# The code below is copied from JRuby 9.1.16.0 resolv.rb:
# https://github.com/jruby/jruby/blob/9.1.16.0/lib/ruby/stdlib/resolv.rb#L775-L784
#
# JRuby is Copyright (c) 2007-2017 The JRuby project, and is released
# under a tri EPL/GPL/LGPL license.
# Full license available at https://github.com/jruby/jruby/blob/9.1.16.0/COPYING
