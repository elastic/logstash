---
title: Getting Started (Standalone server) - logstash
layout: content_right
---
# Getting started with logstash (standalone server example)

This guide shows how to get you going quickly with logstash on a single,
standalone server. We'll begin by showing you how to read events from standard
input (your keyboard) and emit them to standard output. After that, we'll start
collecting actual log files.

By standalone, I mean that everything happens on a single server: log collection, indexing, and the web interface.

logstash can be run on multiple servers (collect from many servers to a single
indexer) if you want, but this example shows simply a standalone configuration.

Steps detailed in this guide:

* Download and run logstash

## Problems?

If you have problems, feel free to email the users list
(logstash-users@googlegroups.com) or join IRC (#logstash on irc.freenode.org)

## logstash

You should download the logstash jar file - if you haven't yet,
[download it
now](http://logstash.objects.dreamhost.com/release/logstash-1.2.0.beta1-flatjar.jar).
This package includes most of the dependencies for logstash in it and
helps you get started quicker.

The configuration of any logstash agent consists of specifying inputs, filters,
and outputs. For this example, we will not configure any filters.

The inputs are your log files. The output will be elasticsearch. The config
format should be simple to read and write. The bottom of this document includes
links for further reading (config, etc) if you want to learn more.

Here is the simplest Logstash configuration you can work with:

    input { stdin { type => "stdin-type"}}
    output { stdout { debug => true debug_format => "json"}}

Save this to a file called `logstash-simple.conf` and run it like so:

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f logstash-simple.conf

After a few seconds, type something in the console where you started logstash. Maybe `test`.
You should get some output like so:

    {
      "@source":"stdin://jvstratusmbp.local/",
     "@type":"stdin",
     "@tags":[],
     "@fields":{},
     "@timestamp":"2012-07-02T05:20:16.092000Z",
     "@source_host":"jvstratusmbp.local",
     "@source_path":"/",
     "@message":"test"
    }

If everything is okay, let's move on to a more complex version:

### Saving to Elasticsearch
The recommended storage engine for Logstash is Elasticsearch. If you're running Logstash from the jar file or via jruby, you can use an embedded version of Elasticsearch for storage.

Using our configuration above, let's change it to look like so:

    input { stdin { type => "stdin-type"}}
    output { 
      stdout { debug => true debug_format => "json"}
      elasticsearch { embedded => true }
    }

We're going to KEEP the existing configuration but add a second output - embedded Elasticsearch.
Restart your Logstash (CTRL-C and rerun the java command). Depending on the horsepower of your machine, this could take some time.
Logstash needs to extract the jar contents to a working directory AND start an instance of Elasticsearch.

Let's do our test again by simply typing `test`. You should get the same output to the console.
Now let's verify that Logstash stored the message in Elasticsearch:

    curl -s http://127.0.0.1:9200/_status?pretty=true | grep logstash

_This assumes you have the `curl` command installed._

You should get back some output like so:

    "logstash-2012.07.02" : {
      "index" : "logstash-2012.07.02"

This means Logstash created a new index based on today's date. Likely your data is in there as well:

`curl -s -XGET http://localhost:9200/logstash-2012.07.02/_search?q=@type:stdin`

This will return a rather large JSON output. We're only concerned with a subset:

    "_index": "logstash-2012.07.02",
    "_type": "stdin",
    "_id": "JdRaI5R6RT2do_WhCYM-qg",
    "_score": 0.30685282,
    "_source": {
        "@source": "stdin://dist/",
        "@type": "stdin",
        "@tags": [
            "tag1",
            "tag2"
        ],
        "@fields": {},
        "@timestamp": "2012-07-02T06:17:48.533000Z",
        "@source_host": "dist",
        "@source_path": "/",
        "@message": "test"
    }

Your output may look a little different.
The reason we're going about it this way is to make absolutely sure that we have all the bits working before adding more complexity.

If you are unable to get these steps working, you likely have something interfering with multicast traffic. This has been known to happen when connected to VPNs for instance.
For best results, test on a Linux VM or system with less complicated networking. If in doubt, rerun the command with the options `-vv` and paste the output to Github Gist or Pastie.
Hop on the logstash IRC channel or mailing list and ask for help with that output as reference.

Obviously this is fairly useless this way. Let's add the final step and test with the builtin logstash web ui:

### Testing the webui
We've already proven that events can make it into Elasticsearch. However using curl for everything is less than ideal.
Logstash ships with a built-in web interface. It's fairly spartan but it's a good proof-of-concept. Let's restart our logstash process with an additional option:

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f logstash-simple.conf -- web

One important thing to note is that the `web` option is actually its own set of commmand-line options. We're essentially starting two programs in one.
This is worth remembering as you move to an external Elasticsearch server. The options you specify in your logstash.conf have no bearing on the web ui. It has its own options.

Again, the reason for testing without the web interface is to ensure that the logstash agent itself is getting events into Elasticsearch. This is different than the Logstash web ui being able to read them.
As before we'll need to wait a bit for everything to spin up. You can verify that everything is running (assuming you aren't running with any `-v` options) by checking the output of `netstat`:

    netstat -napt | grep -i LISTEN

What's interesting is that you should see the following ports in use:

- 9200
- 9300
- 9301
- 9302
- 9292

The `9200` and `9300` ports are the embedded ES listening. The `9301` and `9302` ports are the agent and web interfaces talking to ES. `9292` is the port the web ui listens on.

If you open a browser to http://localhost:9292/ and click on the link in the body, you should see results. If not, switch back to your console, type some test and hit return.
Refresh the browser page and you should have results!

### Continuing on
At this point you have a working self-contained Logstash instance. However typing things into stdin is likely not to be what you want.

Here is a sample config you can start with. It defines some basic inputs
grouped by type and two outputs.

    input {
      stdin {
        type => "stdin-type"
      }

      file {
        type => "syslog"

        # Wildcards work, here :)
        path => [ "/var/log/*.log", "/var/log/messages", "/var/log/syslog" ]
      }
    }

    output {
      stdout { }
      elasticsearch { embedded => true }
    }

Put this in a file called "logstash-complex.conf"

Now run it all (again. Be sure to stop your previous Logstash tests!):

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f logstash-complex.conf -- web

Point your browser at <http://yourserver:9292> and start searching!

*Note*: If things are not working, such as you get an error message while
searching, like 'SERVICE_UNAVAILABLE' or some other elasticsearch error, you
should check that your firewall (local, too) is not blocking multicast.

## Further reading

Want to know more about the configuration language? Check out the
[configuration](../configuration) documentation.

You may have logs on many servers you want to centralize through logstash. To
learn how to do that, [read this](getting-started-centralized)
