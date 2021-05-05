<!-- Type of change
Please label this PR with the release version and one of the following labels, depending on the scope of your change:
- bug
- enhancement
- breaking change
- doc
-->

## Release notes
<!-- Add content to appear in  [Release Notes](https://www.elastic.co/guide/en/logstash/current/releasenotes.html), or add [rn:skip] to leave this PR out of release notes -->


## What does this PR do?

<!-- Mandatory
Explain here the changes you made on the PR. Please explain the WHAT: patterns used, algorithms implemented, design architecture, message processing, etc.

Example:
  Expose 'xpack.monitoring.elasticsearch.proxy' in the docker environment variables and update logstash.yml to surface this config option.
  
  This commit exposes the 'xpack.monitoring.elasticsearch.proxy' variable in the docker by adding it in env2yaml.go, which translates from
  being an environment variable to a proper yaml config.
  
  Additionally, this PR exposes this setting for both xpack monitoring & management to the logstash.yml file.
-->

## Why is it important/What is the impact to the user?

<!-- Mandatory
Explain here the WHY or the IMPACT to the user, or the rationale/motivation for the changes.

Example:
  This PR fixes an issue that was preventing the docker image from using the proxy setting when sending xpack monitoring information.
  and/or
  This PR now allows the user to define the xpack monitoring proxy setting in the docker container.
-->

## Checklist

<!-- Mandatory
Add a checklist of things that are required to be reviewed in order to have the PR approved

List here all the items you have verified BEFORE sending this PR. Please DO NOT remove any item, striking through those that do not apply. (Just in case, strikethrough uses two tildes. ~~Scratch this.~~)
-->

- [ ] My code follows the style guidelines of this project
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] I have made corresponding change to the default configuration files (and/or docker env variables)
- [ ] I have added tests that prove my fix is effective or that my feature works

## Author's Checklist

<!-- Recommended
Add a checklist of things that are required to be reviewed in order to have the PR approved
-->
- [ ]

## How to test this PR locally

<!-- Recommended
Explain here how this PR will be tested by the reviewer: commands, dependencies, steps, etc.
-->

## Related issues

<!-- Recommended
Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it.

- Closes #123
- Relates #123
- Requires #123
- Superseeds #123
-->
- 

## Use cases

<!-- Recommended
Explain here the different behaviors that this PR introduces or modifies in this project, user roles, environment configuration, etc.

If you are familiar with Gherkin test scenarios, we recommend its usage: https://cucumber.io/docs/gherkin/reference/
-->

## Screenshots

<!-- Optional
Add here screenshots about how the project will be changed after the PR is applied. They could be related to web pages, terminal, etc, or any other image you consider important to be shared with the team.
-->

## Logs

<!-- Recommended
Paste here output logs discovered while creating this PR, such as stack traces or integration logs, or any other output you consider important to be shared with the team.
-->
