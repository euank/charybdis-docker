#!/bin/bash

########################################################
# This is the main config file for letsencrypt.sh      #
#                                                      #
# This file is looked for in the following locations:  #
# $SCRIPTDIR/config.sh (next to this script)           #
# /usr/local/etc/letsencrypt.sh/config.sh              #
# /etc/letsencrypt.sh/config.sh                        #
# ${PWD}/config.sh (in current working-directory)      #
#                                                      #
# Default values of this config are in comments        #
########################################################

CHALLENGETYPE="dns-01"

# Program or function called in certain situations
#
# After generating the challenge-response, or after failed challenge (in this case altname is empty)
# Given arguments: clean_challenge|deploy_challenge altname token-filename token-content
#
# After successfully signing certificate
# Given arguments: deploy_cert domain path/to/privkey.pem path/to/cert.pem path/to/fullchain.pem
#
# BASEDIR and WELLKNOWN variables are exported and can be used in an external program
# default: <unset>
HOOK=./hook.sh

# Minimum days before expiration to automatically renew certificate (default: 30)
RENEW_DAYS="50"

# Regenerate private keys instead of just signing new certificates on renewal (default: no)
#PRIVATE_KEY_RENEW="no"

# Which public key algorithm should be used? Supported: rsa, prime256v1 and secp384r1
#KEY_ALGO=rsa

# E-mail to use during the registration (default: <unset>)
CONTACT_EMAIL=${LE_EMAIL}
