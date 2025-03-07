---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/community-maintainer.html
---

# Logstash Plugins Community Maintainer Guide [community-maintainer]

This document, to be read by new Maintainers, should explain their responsibilities.  It was inspired by the [C4](http://rfc.zeromq.org/spec:22) document from the ZeroMQ project.  This document is subject to change and suggestions through Pull Requests and issues are strongly encouraged.


## Contribution Guidelines [_contribution_guidelines]

For general guidance around contributing to Logstash Plugins, see the [*Contributing to Logstash*](/extend/index.md) section.


## Document Goals [_document_goals]

To help make the Logstash plugins community participation easy with positive feedback.

To increase diversity.

To reduce code review, merge and release dependencies on the core team by providing support and tools to the Community and Maintainers.

To support the natural life cycle of a plugin.

To codify the roles and responsibilities of: Maintainers and Contributors with specific focus on patch testing, code review, merging and release.


## Development Workflow [_development_workflow]

All Issues and Pull Requests must be tracked using the Github issue tracker.

The plugin uses the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0). Maintainers should check whether a patch introduces code which has an incompatible license. Patch ownership and copyright is defined in the Elastic [Contributor License Agreement](https://www.elastic.co/contributor-agreement) (CLA).


### Terminology [_terminology_2]

A "Contributor" is a role a person assumes when providing a patch. Contributors will not have commit access to the repository. They need to sign the Elastic [Contributor License Agreement](https://www.elastic.co/contributor-agreement) before a patch can be reviewed. Contributors can add themselves to the plugin Contributor list.

A "Maintainer" is a role a person assumes when maintaining a plugin and keeping it healthy, including triaging issues, and reviewing and merging patches.


### Patch Requirements [_patch_requirements]

A patch is a minimal and accurate answer to exactly one identified and agreed upon problem. It must conform to the [code style guidelines](https://github.com/elastic/logstash/blob/main/STYLE.md) and must include RSpec tests that verify the fitness of the solution.

A patch will be automatically tested by a CI system that will report on the Pull Request status.

A patch CLA will be automatically verified and reported on the Pull Request status.

A patch commit message has a single short (less than 50 character) first line summarizing the change, a blank second line, and any additional lines as necessary for change explanation and rationale.

A patch is mergeable when it satisfies the above requirements and has been reviewed positively by at least one other person.


### Development Process [_development_process]

A user will log an issue on the issue tracker describing the problem they face or observe with as much detail as possible.

To work on an issue, a Contributor forks the plugin repository and then works on their forked repository and submits a patch by creating a pull request back to the plugin.

Maintainers must not merge patches where the author has not signed the CLA.

Before a patch can be accepted it should be reviewed. Maintainers should merge accepted patches without delay.

Maintainers should not merge their own patches except in exceptional cases, such as non-responsiveness from other Maintainers or core team for an extended period (more than 2 weeks).

Reviewer’s comments should not be based on personal preferences.

The Maintainers should label Issues and Pull Requests.

Maintainers should involve the core team if help is needed to reach consensus.

Review non-source changes such as documentation in the same way as source code changes.


### Branch Management [_branch_management]

The plugin has a main branch that always holds the latest in-progress version and should always build.  Topic branches should kept to the minimum.


### Changelog Management [_changelog_management]

Every plugin should have a changelog (https://www.elastic.co/guide/en/logstash/current/CHANGELOG.html).  If not, please create one.  When changes are made to a plugin, make sure to include a changelog entry under the respective version to document the change.  The changelog should be easily understood from a user point of view.  As we iterate and release plugins rapidly, users use the changelog as a mechanism for deciding whether to update.

Changes that are not user facing should be tagged as `internal:`.  For example:

```markdown
 - internal: Refactored specs for better testing
 - config: Default timeout configuration changed from 10s to 5s
```


#### Detailed format of https://www.elastic.co/guide/en/logstash/current/CHANGELOG.html [_detailed_format_of_changelog_md]

Sharing a similar format of https://www.elastic.co/guide/en/logstash/current/CHANGELOG.html in plugins ease readability for users. Please see following annotated example and see a concrete example in [logstash-filter-date](https://raw.githubusercontent.com/logstash-plugins/logstash-filter-date/main/https://www.elastic.co/guide/en/logstash/current/CHANGELOG.html).

```markdown
## 1.0.x                              <1>
 - change description                 <2>
 - tag: change description            <3>
 - tag1,tag2: change description      <4>
 - tag: Multi-line description        <5>
   must be indented and can use
   additional markdown syntax
                                      <6>
## 1.0.0                              <7>
[...]
```

1. Latest version is the first line of https://www.elastic.co/guide/en/logstash/current/CHANGELOG.html. Each version identifier should be a level-2 header using `##`
2. One change description is described as a list item using a dash `-` aligned under the version identifier
3. One change can be tagged by a word and suffixed by `:`.<br> Common tags are `bugfix`, `feature`, `doc`, `test` or `internal`.
4. One change can have multiple tags separated by a comma and suffixed by `:`
5. A multi-line change description must be properly indented
6. Please take care to **separate versions with an empty line**
7. Previous version identifier



### Continuous Integration [_continuous_integration]

Plugins are setup with automated continuous integration (CI) environments and there should be a corresponding badge on each Github page.  If it’s missing, please contact the Logstash core team.

Every Pull Request opened automatically triggers a CI run.  To conduct a manual run, comment “Jenkins, please test this.” on the Pull Request.


## Versioning Plugins [_versioning_plugins]

Logstash core and its plugins have separate product development lifecycles. Hence the versioning and release strategy for the core and plugins do not have to be aligned. In fact, this was one of our goals during the great separation of plugins work in Logstash 1.5.

At times, there will be changes in core API in Logstash, which will require mass update of plugins to reflect the changes in core. However, this does not happen frequently.

For plugins, we would like to adhere to a versioning and release strategy that can better inform our users, about any breaking changes to the Logstash configuration formats and functionality.

Plugin releases follows a three-placed numbering scheme X.Y.Z. where X denotes a major release version which may break compatibility with existing configuration or functionality. Y denotes releases which includes features which are backward compatible. Z denotes releases which includes bug fixes and patches.


### Changing the version [_changing_the_version]

Version can be changed in the Gemspec, which needs to be associated with a changelog entry. Following this, we can publish the gem to RubyGem.org manually. At this point only the core developers can publish a gem.


### Labeling [_labeling]

Labeling is a critical aspect of maintaining plugins. All issues in GitHub should be labeled correctly so it can:

* Provide good feedback to users/developers
* Help prioritize changes
* Be used in release notes

Most labels are self explanatory, but here’s a quick recap of few important labels:

* `bug`: Labels an issue as an unintentional defect
* `needs details`: If a the issue reporter has incomplete details, please ask them for more info and label as needs details.
* `missing cla`: Contributor License Agreement is missing and patch cannot be accepted without it
* `adopt me`: Ask for help from the community to take over this issue
* `enhancement`: New feature, not a bug fix
* `needs tests`: Patch has no tests, and cannot be accepted without unit/integration tests
* `docs`: Documentation related issue/PR


## Logging [_logging]

Although it’s important not to bog down performance with excessive logging, debug level logs can be immensely helpful when diagnosing and troubleshooting issues with Logstash.  Please remember to liberally add debug logs wherever it makes sense as users will be forever gracious.

```shell
@logger.debug("Logstash loves debug logs!", :actions => actions)
```


## Contributor License Agreement (CLA) Guidance [_contributor_license_agreement_cla_guidance]

Why is a [CLA](https://www.elastic.co/contributor-agreement) required?
:   We ask this of all Contributors in order to assure our users of the origin and continuing existence of the code. We are not asking Contributors to assign copyright to us, but to give us the right to distribute a Contributor’s code without restriction.

Please make sure the CLA is signed by every Contributor prior to reviewing PRs and commits.
:   Contributors only need to sign the CLA once and should sign with the same email as used in Github. If a Contributor signs the CLA after a PR is submitted, they can refresh the automated CLA checker by pushing another comment on the PR after 5 minutes of signing.


## Need Help? [_need_help]

Ping @logstash-core on Github to get the attention of the Logstash core team.


## Community Administration [_community_administration]

The core team is there to support the plugin Maintainers and overall ecosystem.

Maintainers should propose Contributors to become a Maintainer.

Contributors and Maintainers should follow the Elastic Community [Code of Conduct](https://www.elastic.co/community/codeofconduct).  The core team should block or ban "bad actors".

