**Features**

## Generating the documentation for a Logstash instance

You can now generate the documentation for a Logstash distribution.

*prerequisite*:

- You need to have installed the plugins inside Logstash, this is necessary to pickup the right file when generating the documentation.
- You need to have the development gems installed. `bin/logstash-plugin --no-verify --development`

If you have all of the above you can run this command:

```sh
rake doc:generate-plugins
rake doc:generate-plugins[/tmp/the-new-doc] # Depending on the shell you are using you might need to quote the task name, like this rake "doc:generate-plugins[/tmp/new-doc]"
```

This will give you a output similar to this

```sh
logstash-input-file > SUCCESS
logstash-input-s3 > SUCCESS
logstash-input-kafka > FAIL
[...]
Exceptions: XXXX
```

The generator will try to generate the doc for all the plugins defined in the *Gemfile* and installed in Logstash, if anything goes wrong it won't
stop the generation of the other plugin. The Task will also report any errors with stacktraces at the end, if one plugin fail the build,
you can interrupt the process and it will output the current errors before exiting.


## Generating the documentation for all the plugins from the organization

You can now generate the documentation from main for all the plugin in the *logstash-plugins* organization.

*prerequisite*

- You need to go in the `tools/logstash-docgen` directory
- You need to have the dependency installed.

 To get started you can run the following commands:

 ```sh
 cd tools/logstash-docgen
 bundle install
 ```

You can use the the `bin/logstash-docgen` command to generate any plugin that you want, this executable can generate all the plugins or specific one from their main branch.

Usages:

```sh
bin/logstash-docgen --all # will generate the doc for all the plugins
bin/logstash-docgen logstash-input-file logstash-input-s3 # generate doc for 2 plugins
```

**See:** `bin/logstash-docgen --help` for complete usage.

**Notes:**
- The nature of theses tasks require a lot of external execution to make sure all the doc are done in isolation, this process can take a long time.
- Some plugins will be skipped, see `logstash-docgen.yml` for details.
- The script will inject itself as a dependency on the plugin.


## Testing the documentation as the plugin author

*prerequisite*

- Declare the `logstash-docgen` as development dependency
- Add `require "logstash/docgen/plugin_doc"` to the `Rakefile`
- Run `bundle install`

After you can have access to a few rake tasks, you can list them with `bundle exec rake -T`

```
bundle exec rake doc:asciidoc # return the raw asciidoc
bundle exec rake doc:html # Give you the raw html
```

## CI test

The CI can use the `ci/docs.sh` script to correctly bootstrap and execute the docgeneration


