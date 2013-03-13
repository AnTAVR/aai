#!/bin/bash
awk "{print \"\${template0 \"\$1\"}\"}" <(ifconfig | grep "flags=" | grep -v "lo:" | cut -d ":" -f1)
