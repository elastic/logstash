# Contributing to Logstash

All contributions are welcome: ideas, patches, documentation, bug reports,
complaints, etc!

Programming is not a required skill, and there are many ways to help out!
It is more important to us that you are able to contribute.

That said, some basic guidelines, which you are free to ignore :)

## Want to learn?

Want to lurk about and see what others are doing with Logstash?

* The irc channel (#logstash on irc.freenode.org) is a good place for this
* The [forum](https://discuss.elastic.co/c/logstash) is also
  great for learning from others.

## Got Questions?

Have a problem you want Logstash to solve for you?

* You can ask a question in the [forum](https://discuss.elastic.co/c/logstash)
* Alternately, you are welcome to join the IRC channel #logstash on
irc.freenode.org and ask for help there!

## Have an Idea or Feature Request?

* File a ticket on [GitHub](https://github.com/elastic/logstash/issues). Please remember that GitHub is used only for issues and feature requests. If you have a general question, the [forum](https://discuss.elastic.co/c/logstash) or IRC would be the best place to ask.

## Something Not Working? Found a Bug?

If you think you found a bug, it probably is a bug.

* If it is a general Logstash or a pipeline issue, file it in [Logstash GitHub](https://github.com/elasticsearch/logstash/issues)
* If it is specific to a plugin, please file it in the respective repository under [logstash-plugins](https://github.com/logstash-plugins)
* or ask the [forum](https://discuss.elastic.co/c/logstash).

## Issue Prioritization
The Logstash team takes time to digest, consider solutions, and weigh applicability of issues to both the broad
Logstash user base and our own goals for the project. Through this process, we triage and update issues as we get to them. Please provide context in your issues instead of just adding a +1 comment. If you like a certain idea or enhancement, and have nothing more to add, please just use GitHub :+1: emoji.

# Contributing Documentation and Code Changes

If you have a bugfix or new feature that you would like to contribute to Logstash, and you think it will take
more than a few minutes to produce the fix (ie; write code), it is worth discussing the change with the Logstash
users and developers first. You can reach us via [GitHub](https://github.com/elastic/logstash/issues), the [forum](https://discuss.elastic.co/c/logstash), or via IRC (#logstash on freenode irc)

Please note that Pull Requests without tests and documentation may not be merged. If you would like to contribute but do not have
experience with writing tests, please ping us on IRC/forum or create a PR and ask our help.

If you would like to contribute to Logstash, but don't know where to start, you can use the GitHub labels "adoptme"
and "low hanging fruit". Issues marked with these labels are relatively easy, and provides a good starting
point to contribute to Logstash.

See: https://github.com/elastic/logstash/labels/adoptme
https://github.com/elastic/logstash/labels/low%20hanging%20fruit

Using IntelliJ? See a detailed getting started guide [here](https://docs.google.com/document/d/1kqunARvYMrlfTEOgMpYHig0U-ZqCcMJfhvTtGt09iZg/pub).

## Contributing to plugins

Check our [documentation](https://www.elastic.co/guide/en/logstash/current/contributing-to-logstash.html) on how to contribute to plugins or write your own!

## Contribution Steps

1. Test your changes! [Run](https://github.com/elastic/logstash#testing) the test suite
2. Please make sure you have signed our [Contributor License
   Agreement](https://www.elastic.co/contributor-agreement/). We are not
   asking you to assign copyright to us, but to give us the right to distribute
   your code without restriction. We ask this of all contributors in order to
   assure our users of the origin and continuing existence of the code. You
   only need to sign the CLA once.
3. Send a pull request! Push your changes to your fork of the repository and
   [submit a pull
   request](https://help.github.com/articles/using-pull-requests). In the pull
   request, describe what your changes do and mention any bugs/issues related
   to the pull request.
   
# Pull Request Guidelines

The following exists as a way to set expectations for yourself and for the review process. We *want* to merge fixes and features, so let's describe how we can achieve this:
   
## Goals

* To constantly make forward progress on PRs

* To have constructive discussions on PRs

## Overarching Guiding Principles

Keep these in mind as both authors and reviewers of PRs:

* Have empathy in both directions (reviewer <--> reviewee/author)
* Progress over perfection and personal preferences

## As a reviewee (i.e. author) of a PR:

* I must put up atomic PRs. This helps the reviewer of the PR do a high quality review fast. "Atomic" here means two things:
  - The PR must contain related changes and leave out unrelated changes (e.g. refactorings, etc. that could be their own PR instead).
  - If the PR could be broken up into two or more PRs either "vertically" (by separating concerns logically) or horizontally (by sharding the PR into a series of PRs --- usually works well with mass refactoring or cleanup type PRs), it should. A set of such related PRs can be tracked and given context in a meta issue.

* I must strive to please the reviewer(s). In other words, bias towards taking the reviewers suggestions rather than getting into a protracted argument. This helps move the PR forward. A convenient "escape hatch" to use might be to file a new issue for a follow up discussion/PR. If you find yourself getting into a drawn out argument, ask yourself: is this a good use of our time?

## As a reviewer of a PR:

* I must first focus on whether the PR works functionally -- i.e. does it solve the problem (bug, feature, etc.) it sets out to solve.

* Then I should ask myself: can I understand what the code in this PR is doing and, more importantly, why its doing whatever its doing, within 1 or 2 passes over the PR?

  * If yes, LGTM the PR!

  * If no, ask for clarifications on the PR. This will usually lead to changes in the code such as renaming of variables/functions or extracting of functions or simply adding "why" inline comments. But first ask the author for clarifications before assuming any intent on their part.

* I must not focus on personal preferences or nitpicks. If I understand the code in the PR but simply would've implemented the same solution a different way that's great but its not feedback that belongs in the PR. Such feedback only serves to slow down progress for little to no gain.

