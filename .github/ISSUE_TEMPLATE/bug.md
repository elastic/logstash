---
name: Bug
about: "Report a confirmed bug. For unconfirmed bugs please
 visit https://discuss.elastic.co/c/logstash"
labels: "bug,status:needs-triage"

---
<!--
GitHub is reserved for bug reports and feature requests; it is not the place
for general questions. If you have a question or an unconfirmed bug , please
visit the [forums](https://discuss.elastic.co/c/logstash).  Please also
check your OS is [supported](https://www.elastic.co/support/matrix#show_os).
If it is not, the issue is likely to be closed.

Logstash Plugins are located in a different organization: [logstash-plugins](https://github.com/logstash-plugins). For bugs on specific Logstash plugins, for example, if Redis Output has a defect, please open it in the respective Redis Output repository.

For security vulnerabilities please only send reports to security@elastic.co.
See https://www.elastic.co/community/security for more information.

Please fill in the following details to help us reproduce the bug:
-->

**Logstash information**:

Please include the following information:

1. Logstash version (e.g. `bin/logstash --version`)
2. Logstash installation source (e.g. built from source, with a package manager: DEB/RPM, expanded from tar or zip archive, docker)
3. How is Logstash being run (e.g. as a service/service manager: systemd, upstart, etc. Via command line, docker/kubernetes)

**Plugins installed**: (`bin/logstash-plugin list --verbose`)

**JVM** (e.g. `java -version`):

If the affected version of Logstash is 7.9 (or earlier), or if it is NOT using the bundled JDK or using the 'no-jdk' version in 7.10 (or higher), please provide the following information:

1. JVM version (`java -version`)
2. JVM installation source (e.g. from the Operating System's package manager, from source, etc).
3. Value of the `LS_JAVA_HOME` environment variable if set.

**OS version** (`uname -a` if on a Unix-like system):

**Description of the problem including expected versus actual behavior**:

**Steps to reproduce**:

Please include a *minimal* but *complete* recreation of the problem,
including (e.g.) pipeline definition(s), settings, locale, etc.  The easier
you make for us to reproduce it, the more likely that somebody will take the
time to look at it.

 1.
 2.
 3.

**Provide logs (if relevant)**:
