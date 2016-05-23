#!/usr/bin/env bash

zypper rr systemsmanagement_puppet
zypper addrepo -t yast2 http://demeter.uni-regensburg.de/SLES12-x64/DVD1/ dvd1 || true
zypper addrepo -t yast2 http://demeter.uni-regensburg.de/SLES12-x64/DVD2/ dvd2 || true
zypper addrepo http://download.opensuse.org/repositories/Java:Factory/SLE_12/Java:Factory.repo || true
zypper --no-gpg-checks --non-interactive refresh
zypper --non-interactive list-updates
zypper --non-interactive --no-gpg-checks --quiet install --no-recommends java-1_8_0-openjdk-devel
