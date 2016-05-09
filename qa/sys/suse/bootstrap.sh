#!/usr/bin/env bash

zypper --non-interactive list-updates
zypper --non-interactive --no-gpg-checks --quiet install --no-recommends java-1_8_0-openjdk-devel
