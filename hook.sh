#!/bin/bash
set -x


function get_zone {
    local DOMAIN="${1}"
    last_char=$(echo $DOMAIN | grep -o ".$")
    if [ $last_char != "." ]; then
        # Normalize "example.com" to "example.com." since all hosted zones have that format in name
        DOMAIN="${DOMAIN}."
    fi

    zone=$(aws route53 list-hosted-zones | jq ".HostedZones[] | . as \$zone | select(\"${DOMAIN}\" | endswith(\$zone.Name)) | .Id" -r)
    if [ -z "$zone" ]; then
        echo "Failed to find zone id for $DOMAIN"
        exit 1
    fi

    echo $zone
}


function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    # This hook is called once for every domain that needs to be
    # validated, including any alternative names you may have listed.
    #
    # Parameters:
    # - DOMAIN
    #   The domain name (CN or subject alternative name) being
    #   validated.
    # - TOKEN_FILENAME
    #   The name of the file containing the token to be served for HTTP
    #   validation. Should be served by your web server as
    #   /.well-known/acme-challenge/${TOKEN_FILENAME}.
    # - TOKEN_VALUE
    #   The token value that needs to be served for validation. For DNS
    #   validation, this is what you want to put in the _acme-challenge
    #   TXT record. For HTTP validation it is the value that is expected
    #   be found in the $TOKEN_FILENAME file.

    # Route53 DNS challange
    zone=$(get_zone $DOMAIN) || exit 1
    aws route53 change-resource-record-sets --hosted-zone-id "$zone" --change-batch "{\"Comment\": \"lets encrypt.sh\", \"Changes\": [{\"Action\": \"UPSERT\", \"ResourceRecordSet\": {\"Name\": \"_acme-challenge.${DOMAIN}\", \"Type\": \"TXT\", \"TTL\": 0, \"ResourceRecords\": [{\"Value\": \"\\\"${TOKEN_VALUE}\\\"\"}]}}]}"

    sleep 30
}


function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    # This hook is called after attempting to validate each domain,
    # whether or not validation was successful. Here you can delete
    # files or DNS records that are no longer needed.
    #
    # The parameters are the same as for deploy_challenge.

    zone=$(get_zone $DOMAIN) || exit 1
    aws route53 change-resource-record-sets --hosted-zone-id "$zone" --change-batch "{\"Comment\": \"lets encrypt.sh\", \"Changes\": [{\"Action\": \"DELETE\", \"ResourceRecordSet\": {\"Name\": \"_acme-challenge.${DOMAIN}\", \"Type\": \"TXT\", \"TTL\": 0, \"ResourceRecords\": [{\"Value\": \"\\\"${TOKEN_VALUE}\\\"\"}]}}]}"
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" CHAINFILE="${4}"

    # This hook is called once for each certificate that has been
    # produced. Here you might, for instance, copy your new certificates
    # to service-specific locations and reload the service.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - KEYFILE
    #   The path of the file containing the private key.
    # - CERTFILE
    #   The path of the file containing the signed certificate.
    # - CHAINFILE
    #   The path of the file containing the full certificate chain.
    cp $KEYFILE /ssl/ssl.key;
    cat $CHAINFILE $CERTFILE > /ssl/ssl.pem;
}

HANDLER=$1; shift; $HANDLER $@
