#!/bin/bash
awk "{print \"\${template2 \"\$1+1\" \"\$1\"}\"}" <(cat /proc/cpuinfo | grep "processor" | cut -d ":" -f2)
