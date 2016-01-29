#!/bin/sh

if [ -z "${LE_EMAIL}" ]; then
  echo "We need an email for let's encrypt"
  exit 1
fi

if [ -z "${DOMAIN}" ]; then
  echo "We need a domain"
  exit 1
fi

while true; do
  ./letsencrypt.sh --domain "$DOMAIN" --config ./config.sh --cron
  sleep 3600
done
