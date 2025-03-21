---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/contributing-patch-plugin.html
---

# Contributing a patch to a Logstash plugin [contributing-patch-plugin]

This section discusses the information you need to know to successfully contribute a patch to a Logstash plugin.

Each plugin defines its own configuration options. These control the behavior of the plugin to some degree. Configuration option definitions commonly include:

* Data validation
* Default value
* Any required flags

Plugins are subclasses of a Logstash base class. A plugin’s base class defines common configuration and methods.

## Input plugins [contrib-patch-input]

Input plugins ingest data from an external source. Input plugins are always associated with a codec. An input plugin always has an associated codec plugin. Input and codec plugins operate in conjunction to create a Logstash event and add that event to the processing queue. An input codec is a subclass of the `LogStash::Inputs::Base` class.

### Input API [input-api]

`#register() -> nil`
:   Required. This API sets up resources for the plugin, typically the connection to the external source.

`#run(queue) -> nil`
:   Required. This API fetches or listens for source data, typically looping until stopped. Must handle errors inside the loop. Pushes any created events to the queue object specified in the method argument. Some inputs may receive batched data to minimize the external call overhead.

`#stop() -> nil`
:   Optional. Stops external connections and cleans up.



## Codec plugins [contrib-patch-codec]

Codec plugins decode input data that has a specific structure, such as JSON input data. A codec plugin is a subclass of `LogStash::Codecs::Base`.

### Codec API [codec-api]

`#register() -> nil`
:   Identical to the API of the same name for input plugins.

`#decode(data){|event| block} -> nil`
:   Must be implemented. Used to create an Event from the raw data given in the method argument. Must handle errors. The caller must provide a Ruby block. The block is called with the created Event.

`#encode(event) -> nil`
:   Required.  Used to create a structured data object from the given Event. May handle errors. This method calls a block that was previously stored as @on_event with two arguments: the original event and the data object.



## Filter plugins [contrib-patch-filter]

A mechanism to change, mutate or merge one or more Events. A filter plugin is a subclass of the `LogStash::Filters::Base` class.

### Filter API [filter-api]

`#register() -> nil`
:   Identical to the API of the same name for input plugins.

`#filter(event) -> nil`
:   Required. May handle errors. Used to apply a mutation function to the given event.



## Output plugins [contrib-patch-output]

A mechanism to send an event to an external destination. This process may require serialization. An output plugin is a subclass of the `LogStash::Outputs::Base` class.

### Output API [output-api]

`#register() -> nil`
:   Identical to the API of the same name for input plugins.

`#receive(event) -> nil`
:   Required. Must handle errors. Used to prepare the given event for transmission to the external destination. Some outputs may buffer the prepared events to batch transmit to the destination.



## Process [patch-process]

A bug or feature is identified. An issue is created in the plugin repository. A patch is created and a pull request (PR) is submitted. After review and possible rework the PR is merged and the plugin is published.

The [Community Maintainer Guide](/extend/community-maintainer.md) explains, in more detail, the process of getting a patch accepted, merged and published.  The Community Maintainer Guide also details the roles that contributors and maintainers are expected to perform.


## Testing methodologies [test-methods]

### Test driven development [tdd]

Test driven development (TDD) describes a methodology for using tests to guide evolution of source code. For our purposes, we are use only a part of it. Before writing the fix, we create tests that illustrate the bug by failing. We stop when we have written enough code to make the tests pass and submit the fix and tests as a patch. It is not necessary to write the tests before the fix, but it is very easy to write a passing test afterwards that may not actually verify that the fault is really fixed especially if the fault can be triggered via multiple execution paths or varying input data.


### RSpec framework [rspec]

Logstash uses Rspec, a Ruby testing framework, to define and run the test suite. What follows is a summary of various sources.

```ruby
 2 require "logstash/devutils/rspec/spec_helper"
 3 require "logstash/plugin"
 4
 5 describe "outputs/riemann" do
 6   describe "#register" do
 7     let(:output) do
 8       LogStash::Plugin.lookup("output", "riemann").new(configuration)
 9     end
10
11     context "when no protocol is specified" do
12       let(:configuration) { Hash.new }
13
14       it "the method completes without error" do
15         expect {output.register}.not_to raise_error
16       end
17     end
18
19     context "when a bad protocol is specified" do
20       let(:configuration) { {"protocol" => "fake"} }
21
22       it "the method fails with error" do
23         expect {output.register}.to raise_error
24       end
25     end
26
27     context "when the tcp protocol is specified" do
28       let(:configuration) { {"protocol" => "tcp"} }
29
30       it "the method completes without error" do
31         expect {output.register}.not_to raise_error
32       end
33     end
34   end
35
36   describe "#receive" do
37     let(:output) do
38       LogStash::Plugin.lookup("output", "riemann").new(configuration)
39     end
40
41     context "when operating normally" do
42       let(:configuration) { Hash.new }
43       let(:event) do
44         data = {"message"=>"hello", "@version"=>"1",
45                 "@timestamp"=>"2015-06-03T23:34:54.076Z",
46                 "host"=>"vagrant-ubuntu-trusty-64"}
47         LogStash::Event.new(data)
48       end
49
50       before(:example) do
51         output.register
52       end
53
54       it "should accept the event" do
55         expect { output.receive event }.not_to raise_error
56       end
57     end
58   end
59 end
```

```ruby
describe(string){block} -> nil
describe(Class){block} -> nil
```

With RSpec, we are always describing the plugin method behavior. The describe block is added in logical sections and can accept either an existing class name or a string. The string used in line 5 is the plugin name. Line 6 is the register method, line 36 is the receive method. It is a RSpec convention to prefix instance methods with one hash and class methods with one dot.

```ruby
context(string){block} -> nil
```

In RSpec, context blocks define sections that group tests by a variation.  The string should start with the word `when` and then detail the variation. See line 11.  The tests in the content block should should only be for that variation.

```ruby
let(symbol){block} -> nil
```

In RSpec, `let` blocks define resources for use in the test blocks. These resources are reinitialized for every test block. They are available as method calls inside the test block. Define `let` blocks in `describe` and `context` blocks, which scope the `let` block and any other nested blocks. You can use other `let` methods defined later within the `let` block body. See lines 7-9, which define the output resource and use the configuration method, defined with different variations in lines 12, 20 and 28.

```ruby
before(symbol){block} -> nil - symbol is one of :suite, :context, :example, but :all and :each are synonyms for :suite and :example respectively.
```

In RSpec, `before` blocks are used to further set up any resources that would have been initialized in a `let` block. You cannot define `let` blocks inside `before` blocks.

You can also define `after` blocks, which are typically used to clean up any setup activity performed by a `before` block.

```ruby
it(string){block} -> nil
```

In RSpec, `it` blocks set the expectations that verify the behavior of the tested code. The string should not start with *it* or *should*, but needs to express the outcome of the expectation.  When put together the texts from the enclosing describe, `context` and `it` blocks should form a fairly readable sentence, as in lines 5, 6, 11 and 14:

```ruby
outputs/riemann
#register when no protocol is specified the method completes without error
```

Readable code like this make the goals of tests easy to understand.

```ruby
expect(object){block} -> nil
```

In RSpec, the expect method verifies a statement that compares an actual result to an expected result. The `expect` method is usually paired with a call to the `to` or `not_to` methods. Use the block form when expecting errors or observing for changes. The `to` or `not_to` methods require a `matcher` object that encapsulates the expected value. The argument form of the `expect` method encapsulates the actual value. When put together the whole line tests the actual against the expected value.

```ruby
raise_error(error class|nil) -> matcher instance
be(object) -> matcher instance
eq(object) -> matcher instance
eql(object) -> matcher instance
  for more see http://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
```

In RSpec, a matcher is an object generated by the equivalent method call (be, eq) that will be used to evaluate the expected against the actual values.



## Putting it all together [all-together]

This example fixes an [issue](https://github.com/logstash-plugins/logstash-output-zeromq/issues/9) in the ZeroMQ output plugin. The issue does not require knowledge of ZeroMQ.

The activities in this example have the following prerequisites:

* A minimal knowledge of Git and Github. See the [Github boot camp](https://help.github.com/categories/bootcamp/).
* A text editor.
* A JRuby [runtime](https://www.ruby-lang.org/en/documentation/installation/#managers) [environment](https://howistart.org/posts/ruby/1). The `chruby` tool manages Ruby versions.
* JRuby 1.7.22 or later.
* The `bundler` and `rake` gems installed.
* ZeroMQ [installed](http://zeromq.org/intro:get-the-software).

1. In Github, fork the ZeroMQ [output plugin repository](https://github.com/logstash-plugins/logstash-output-zeromq).
2. On your local machine, [clone](https://help.github.com/articles/fork-a-repo/) the fork to a known folder such as `logstash/`.
3. Open the following files in a text editor:

    * `logstash-output-zeromq/lib/logstash/outputs/zeromq.rb`
    * `logstash-output-zeromq/lib/logstash/util/zeromq.rb`
    * `logstash-output-zeromq/spec/outputs/zeromq_spec.rb`

4. According to the issue, log output in server mode must indicate `bound`. Furthermore, the test file contains no tests.

    ::::{note}
    Line 21 of `util/zeromq.rb` reads `@logger.info("0mq: #{server? ? 'connected' : 'bound'}", :address => address)`
    ::::

5. In the text editor, require `zeromq.rb` for the file `zeromq_spec.rb` by adding the following lines:

    ```ruby
    require "logstash/outputs/zeromq"
    require "logstash/devutils/rspec/spec_helper"
    ```

6. The desired error message should read:

    ```ruby
    LogStash::Outputs::ZeroMQ when in server mode a 'bound' info line is logged
    ```

    To properly generate this message, add a `describe` block with the fully qualified class name as the argument, a context block, and an `it` block.

    ```ruby
    describe LogStash::Outputs::ZeroMQ do
      context "when in server mode" do
        it "a 'bound' info line is logged" do
        end
      end
    end
    ```

7. To add the missing test, use an instance of the ZeroMQ output and a substitute logger. This example uses an RSpec feature called *test doubles* as the substitute logger.

    Add the following lines to `zeromq_spec.rb`, after `describe LogStash::Outputs::ZeroMQ do` and before `context "when in server mode" do`:

    ```ruby
      let(:output) { described_class.new("mode" => "server", "topology" => "pushpull" }
      let(:tracer) { double("logger") }
    ```

8. Add the body to the `it` block. Add the following five lines after the line `context "when in server mode" do`:

    ```ruby
          allow(tracer).to receive(:debug)<1>
          output.logger = logger<2>
          expect(tracer).to receive(:info).with("0mq: bound", {:address=>"tcp://127.0.0.1:2120"})<3>
          output.register<4>
          output.do_close<5>
    ```


1. Allow the double to receive `debug` method calls.
2. Make the output use the test double.
3. Set an expectation on the test to receive an `info` method call.
4. Call `register` on the output.
5. Call `do_close` on the output so the test does not hang.


At the end of the modifications, the relevant code section reads:

```ruby
require "logstash/outputs/zeromq"
require "logstash/devutils/rspec/spec_helper"

describe LogStash::Outputs::ZeroMQ do
  let(:output) { described_class.new("mode" => "server", "topology" => "pushpull") }
  let(:tracer) { double("logger") }

  context "when in server mode" do
    it "a ‘bound’ info line is logged" do
      allow(tracer).to receive(:debug)
      output.logger = tracer
      expect(tracer).to receive(:info).with("0mq: bound", {:address=>"tcp://127.0.0.1:2120"})
      output.register
      output.do_close
    end
  end
end
```

To run this test:

1. Open a terminal window
2. Navigate to the cloned plugin folder
3. The first time you run the test, run the command `bundle install`
4. Run the command `bundle exec rspec`

Assuming all prerequisites were installed correctly, the test fails with output similar to:

```shell
Using Accessor#strict_set for specs
Run options: exclude {:redis=>true, :socket=>true, :performance=>true, :couchdb=>true, :elasticsearch=>true,
:elasticsearch_secure=>true, :export_cypher=>true, :integration=>true, :windows=>true}

LogStash::Outputs::ZeroMQ
  when in server mode
    a ‘bound’ info line is logged (FAILED - 1)

Failures:

  1) LogStash::Outputs::ZeroMQ when in server mode a ‘bound’ info line is logged
     Failure/Error: output.register
       Double "logger" received :info with unexpected arguments
         expected: ("0mq: bound", {:address=>"tcp://127.0.0.1:2120"})
              got: ("0mq: connected", {:address=>"tcp://127.0.0.1:2120"})
     # ./lib/logstash/util/zeromq.rb:21:in `setup'
     # ./lib/logstash/outputs/zeromq.rb:92:in `register'
     # ./lib/logstash/outputs/zeromq.rb:91:in `register'
     # ./spec/outputs/zeromq_spec.rb:13:in `(root)'
     # /Users/guy/.gem/jruby/1.9.3/gems/rspec-wait-0.0.7/lib/rspec/wait.rb:46:in `(root)'

Finished in 0.133 seconds (files took 1.28 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/outputs/zeromq_spec.rb:10 # LogStash::Outputs::ZeroMQ when in server mode a ‘bound’ info line is logged

Randomized with seed 2568
```

To correct the error, open the `util/zeromq.rb` file in your text editor and swap the positions of the words `connected` and `bound` on line 21. Line 21 now reads:

```ruby
@logger.info("0mq: #{server? ? 'bound' : 'connected'}", :address => address)
```

Run the test again with the `bundle exec rspec` command.

The test passes with output similar to:

```shell
Using Accessor#strict_set for specs
Run options: exclude {:redis=>true, :socket=>true, :performance=>true, :couchdb=>true, :elasticsearch=>true, :elasticsearch_secure=>true, :export_cypher=>true, :integration=>true, :windows=>true}

LogStash::Outputs::ZeroMQ
  when in server mode
    a ‘bound’ info line is logged

Finished in 0.114 seconds (files took 1.22 seconds to load)
1 example, 0 failures

Randomized with seed 45887
```

[Commit](https://help.github.com/articles/fork-a-repo/#next-steps) the changes to git and Github.

Your pull request is visible from the [Pull Requests](https://github.com/logstash-plugins/logstash-output-zeromq/pulls) section of the original Github repository. The plugin maintainers review your work, suggest changes if necessary, and merge and publish a new version of the plugin.


