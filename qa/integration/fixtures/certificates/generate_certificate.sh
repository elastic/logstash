#!/bin/sh
openssl req -subj '/CN=localhost/' -x509 -days $((100 * 365)) -batch -nodes -newkey rsa:2048 -keyout certificate.key -out certificate.crt
