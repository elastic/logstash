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
Logstash user base and our own goals for the project. Through this process, we assign issues a priority using GitHub
labels. Below is a description of priority labels.

* P1: A high priority issue that affects almost all Logstash users. Bugs that would cause data loss, security
issues and test failures. Workarounds for P1s generally don’t exist without a code change. A P1 issue is usually
stop the world kinda scenario, so we need to make sure P1s are properly triaged and being worked upon.
* P2: A broadly applicable, high visibility issue that enhances Logstash usability for a majority of users.
* P3: Nice-to-have bug fixes or functionality.  Workarounds for P3s generally exist.
* P4: Anything not in above, catch-all label.

# Contributing Documentation and Code Changes

If you have a bugfix or new feature that you would like to contribute to Logstash, and you think it will take
more than a few minutes to produce the fix (ie; write code), it is worth discussing the change with the Logstash
users and developers first! You can reach us via [GitHub](https://github.com/elastic/logstash/issues), the [forum](https://discuss.elastic.co/c/logstash), or via IRC (#logstash on freenode irc)
Please note that Pull Requests without tests will not be merged. If you would like to contribute but do not have
experience with writing tests, please ping us on IRC/forum or create a PR and ask our help.

If you would like to contribute to Logstash, but don't know where to start, you can use the GitHub labels "adoptme"
and "low hanging fruit". Issues marked with these labels are relatively easy, and provides a good starting
point to contribute to Logstash.

See: https://github.com/elastic/logstash/labels/adoptme
https://github.com/elastic/logstash/labels/low%20hanging%20fruit

## Contributing to plugins

Check our [documentation](https://www.elastic.co/guide/en/logstash/current/contributing-to-logstash.html) on how to contribute to plugins or write your own! It is super easy!

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
