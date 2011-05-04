---
title: How to extend - logstash
layout: content_right
---
# Extending logstash

You can add your own input, output, or filter plugins to logstash.

DOCS - TBD

If you're looking to extend logstash today, please look at the existing plugins.

Good examples include:

* [inputs/beanstalk](https://github.com/logstash/logstash/blob/master/lib/logstash/inputs/beanstalk.rb)
* [filters/multiline](https://github.com/logstash/logstash/blob/master/lib/logstash/filters/multiline.rb)
* [outputs/mongodb](https://github.com/logstash/logstash/blob/master/lib/logstash/outputs/mongodb.rb)

Main stuff you need to know:

* 'config_name' sets the name used in the config file.
* 'config' lines define config options
* 'register' method is called per plugin instantiation. Do any of your initialization here.

Inputs have two methods: register and run.

* Each input runs as it's own thread.
* the 'run' method is expected to run-forever.

Filters have two methods: register and filter.

* 'filter' method gets an event. 
* Call 'event.cancel' to drop the event.
* To modify an event, simply make changes to the event you are given.
* The return value is ignored.

Outputs have two methods: register and receive.

* 'register' is called per plugin instantiation. Do any of your initialization here.
* 'receive' is called when an event gets pushed to your output
