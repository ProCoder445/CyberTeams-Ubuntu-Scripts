#!/bin/bash

set -eu pipefail;

echo "Starting program.";

((nslookup google.com | grep "SERVFAIL") && echo "SERVFAIL detected!") || exit 0;

if [[ -f /etc/resolv.conf ]]; then
    echo "Found resolv.conf!";
fi
