#!/bin/bash

set -eu

##
## Database setup
##
bundle exec rake setup

##
## Start app
##
bundle exec puma -t 2:2 -p ${PORT:-3000} -e ${RACK_ENV:-development}

# /bin/bash