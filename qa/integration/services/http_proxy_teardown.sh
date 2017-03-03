#!/bin/bash
set -ex

echo "Removing all the chain"
sudo iptables -F OUTPUT
