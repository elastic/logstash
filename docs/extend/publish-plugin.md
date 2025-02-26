---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/publish-plugin.html
---

# Publish your plugin to RubyGems.org [publish-plugin]

Logstash uses [RubyGems.org](http://rubygems.org) as its repository for all plugin artifacts. After you have developed your new plugin, you can make it available to Logstash users by publishing it to RubyGems.org.

## Licensing [_licensing_5]

Logstash and all its plugins are licensed under [Apache License, version 2 ("ALv2")](https://github.com/elasticsearch/logstash/blob/main/LICENSE). If you make your plugin publicly available via [RubyGems.org](http://rubygems.org), please make sure to have this line in your gemspec:

* `s.licenses = ['Apache License (2.0)']`


## Publish to [RubyGems.org](http://rubygems.org) [_publish_to_rubygems_orghttprubygems_org]

You’ll need an account on RubyGems.org

* [Sign-up for a RubyGems account](https://rubygems.org/sign_up).

After creating an account, [obtain](http://guides.rubygems.org/rubygems-org-api/#api-authorization) an API key from RubyGems.org. By default, RubyGems uses the file `~/.gem/credentials` to store your API key. These credentials will be used to publish the gem. Replace `username` and `password` with the credentials you created at RubyGems.org:

```sh
curl -u username:password https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials
chmod 0600 ~/.gem/credentials
```

Before proceeding, make sure you have the right version in your gemspec file and commit your changes.

* `s.version = '0.1.0'`

To publish version 0.1.0 of your new logstash gem:

```sh
bundle install
bundle exec rake vendor
bundle exec rspec
bundle exec rake publish_gem
```

::::{note}
Execute `rake publish_gem`:

1. Reads the version from the gemspec file (`s.version = '0.1.0'`)
2. Checks in your local repository if a tag exists for that version. If the tag already exists, it aborts the process. Otherwise, it creates a new version tag in your local repository.
3. Builds the gem
4. Publishes the gem to RubyGems.org

::::


That’s it! Your plugin is published! Logstash users can now install your plugin by running:

```sh
bin/plugin install logstash-output-mypluginname
```

Where <plugintype> is `input`, `output`, `filter`, or `codec`, and <mypluginname> is the name of your new plugin.


