#!/bin/bash
cat <<EOT > .env
UID=`id -u`
GID=`id -g`
EOT
