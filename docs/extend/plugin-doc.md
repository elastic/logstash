---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugin-doc.html
---

# Document your plugin [plugin-doc]

Documentation is a required component of your plugin. Quality documentation with good examples contributes to the adoption of your plugin.

The documentation that you write for your plugin will be generated and published in the [Logstash Reference](/reference/index.md) and the [Logstash Versioned Plugin Reference](logstash-docs-md://vpr/integration-plugins.md).

::::{admonition} Plugin listing in {{ls}} Reference
:class: note

We may list your plugin in the [Logstash Reference](/reference/index.md) if it meets our [requirements and quality standards](/extend/index.md#plugin-acceptance). When we list your plugin, we point to *your* documentation—​a readme.md, docs/index.asciidoc, or both-​in your plugin repo. For more info on this option, see [List your plugin](/extend/plugin-listing.md).

::::


The following sections contain guidelines for documenting plugins hosted in the Github [logstash-plugins](https://github.com/logstash-plugins/) organization.

## Documentation file [plugin-doc-file]

Documentation belongs in a single file called *docs/index.asciidoc*. It belongs in a single file called *docs/index.asciidoc*. The [plugin generation utility](/reference/plugin-generator.md) creates a starter file for you.


## Heading IDs [heading-ids]

Format heading anchors with variables that can support generated IDs. This approach creates unique IDs when the [Logstash Versioned Plugin Reference](logstash-docs-md://vpr/integration-plugins.md) is built. Unique heading IDs are required to avoid duplication over multiple versions of a plugin.

**Example**

Don’t hardcode a plugin heading ID like this: `[[config_models]]`

Instead, use variables to define it:

```txt
[id="plugins-{type}s-{plugin}-config_models"]
==== Configuration models
```

If you hardcode an ID, the [Logstash Versioned Plugin Reference](logstash-docs-md://vpr/integration-plugins.md) builds correctly the first time. The second time the doc build runs, the ID is flagged as a duplicate, and the build fails.


## Link formats [link-format]

Correct link formatting is essential for directing users to the content you want them to see. Incorrect link formatting or duplicate links can break the documentation build. Let’s not do that.

### Link to content in the same file [_link_to_content_in_the_same_file]

Use angle brackets to format links to content in the same asciidoc file.

**Example**

This link:

```txt
<<plugins-{type}s-{plugin}-config_models>>
```

Points to this heading in the same file:

```txt
[id="plugins-{type}s-{plugin}-config_models"]
==== Configuration models
```


### Link to content in the Logstash Reference Guide [_link_to_content_in_the_logstash_reference_guide]

Use external link syntax for links that point to documentation for other plugins or content in the Logstash Reference Guide.

**Examples**

```txt
{logstash-ref}/plugins-codecs-multiline.html[Multiline codec plugin]
```

```txt
{logstash-ref}/getting-started-with-logstash.html
```


### Link text [_link_text]

If you don’t specify link text, the URL is used as the link text.

**Examples**

If you want your link to display as {{logstash-ref}}/getting-started-with-logstash.html, use this format:

```txt
{logstash-ref}/getting-started-with-logstash.html
```

If you want your link to display as [Getting Started with Logstash](/reference/getting-started-with-logstash.md), use this format:

```txt
{logstash-ref}/getting-started-with-logstash.html[Getting Started with Logstash]
```


### Link to data type descriptions [_link_to_data_type_descriptions]

We make an exception for links that point to data type descriptions, such as `<<boolean,boolean>>`, because they are used so frequently. We have a cleanup step in the conversion script that converts the links to the correct syntax.



## Code samples [format-code]

We all love code samples. Asciidoc supports code blocks and config examples. To include Ruby code, use the asciidoc `[source,ruby]` directive.

Note that the hashmarks (#) are present to make the example render correctly. Don’t include the hashmarks in your asciidoc file.

```txt
# [source,ruby]
# -----
# match => {
#  "field1" => "value1"
#  "field2" => "value2"
#  ...
# }
# -----
```

The sample above (with hashmarks removed) renders in the documentation like this:

```ruby
match => {
  "field1" => "value1"
  "field2" => "value2"
  ...
}
```


## Where’s my doc? [_wheres_my_doc]

Plugin documentation goes through several steps before it gets published in the [Logstash Versioned Plugin Reference](logstash-docs-md://vpr/integration-plugins.md) and the [Logstash Reference](/reference/index.md).

Here’s an overview of the workflow:

* Be sure that you have signed the contributor license agreement (CLA) and have all necessary approvals and sign offs.
* Merge the pull request for your plugin (including the `index.asciidoc` file, the `changelog.md` file, and the gemspec).
* Wait for the continuous integration build to complete successfully.
* Publish the plugin to [https://rubygems.org](https://rubygems.org).
* A script detects the new or changed version, and picks up the `index.asciidoc` file for inclusion in the doc build.
* The documentation for your new plugin is published in the [Logstash Versioned Plugin Reference](logstash-docs-md://vpr/integration-plugins.md).

We’re not done yet.

* For each release, we package the new and changed documentation files into a pull request to add or update content. (We sometimes package plugin docs between releases if we make significant changes to plugin documentation or add a new plugin.)
* The script detects the new or changed version, and picks up the `index.asciidoc` file for inclusion in the doc build.
* We create a pull request, and merge the new and changed content into the appropriate version branches.
* For a new plugin, we add a link to the list of plugins in the [Logstash Reference](/reference/index.md).
* The documentation for your new (or changed) plugin is published in the [Logstash Reference](/reference/index.md).

### Documentation or plugin updates [_documentation_or_plugin_updates]

When you make updates to your plugin or the documentation, consider bumping the version number in the changelog and gemspec (or version file). The version change triggers the doc build to pick up your changes for publishing.



## Resources [_resources]

For more asciidoc formatting tips, see the excellent reference at [https://github.com/elastic/docs#asciidoc-guide](https://github.com/elastic/docs#asciidoc-guide).

For tips on contributing and changelog guidelines, see [CONTRIBUTING.md](https://github.com/elastic/logstash/blob/main/CONTRIBUTING.md#logstash-plugin-changelog-guidelines).

For general information about contributing, see [Contributing to Logstash](/extend/index.md).


