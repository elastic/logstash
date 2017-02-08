# encoding: utf-8

# The version of the logstash package (not the logstash-core gem version).
#
# Note to authors: this should not include dashes because 'gem' barfs if
# you include a dash in the version string.

# TODO: (colin) the logstash-core gem uses it's own version number in logstash-core/lib/logstash-core/version.rb
#       there are some dependencies in logstash-core on the LOGSTASH_VERSION constant this is why
#       the logstash version is currently defined here in logstash-core/lib/logstash/version.rb but
#       eventually this file should be in the root logstash lib fir and dependencies in logstash-core should be
#       fixed.

LOGSTASH_VERSION = "5.4.0"
