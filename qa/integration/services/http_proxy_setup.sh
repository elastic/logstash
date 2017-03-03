#!/bin/bash
set -ex
sudo apt-get install -y squid3 net-tools
sudo iptables -A OUTPUT -p tcp --dport 80 -m owner --uid-owner proxy -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -m owner --uid-owner proxy -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 80 -m owner --uid-owner root -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -m owner --uid-owner root -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 80 -j REJECT

echo "Connecting to a remote host should fails without proxy"
curl -I --silent "http://rubygems.org" || echo "Success"

echo "Connecting to a remote host with a valid proxy should succeed"
export http_proxy=http://localhost:3128
export https_proxy=http://localhost:3128
export HTTP_PROXY=http://localhost:3128
export HTTPS_PROXY=http://localhost:3128
curl -I --silent "https://rubygems.org" || echo "Success"

echo "Unset the default variables"
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
