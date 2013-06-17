#!/bin/bash
awk "{print \"\${template0 \"\$3\" \"\$5\"}\"}" <(mount | grep "dev/sd")
