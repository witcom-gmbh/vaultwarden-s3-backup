#!/bin/bash
set -e
set -o pipefail

function init_env() {

    BACKUP_DIR="/cloudbackup"

    #DATA_DB
    DATA_DB="${DATA_DB:-"${DATA_DIR}/db.sqlite3"}"

    # DATA_CONFIG
    DATA_CONFIG="${DATA_DIR}/config.json"

    # DATA_RSAKEY
    DATA_RSAKEY="${DATA_RSAKEY:-"${DATA_DIR}/rsa_key"}"
    DATA_RSAKEY_DIRNAME="$(dirname "${DATA_RSAKEY}")"
    DATA_RSAKEY_BASENAME="$(basename "${DATA_RSAKEY}")"

    # DATA_ATTACHMENTS
    DATA_ATTACHMENTS="$(dirname "${DATA_ATTACHMENTS:-"${DATA_DIR}/attachments"}/useless")"
    DATA_ATTACHMENTS_DIRNAME="$(dirname "${DATA_ATTACHMENTS}")"
    DATA_ATTACHMENTS_BASENAME="$(basename "${DATA_ATTACHMENTS}")"

    # DATA_SEND
    DATA_SENDS="$(dirname "${DATA_SENDS:-"${DATA_DIR}/sends"}/useless")"
    DATA_SENDS_DIRNAME="$(dirname "${DATA_SENDS}")"
    DATA_SENDS_BASENAME="$(basename "${DATA_SENDS}")"

    if [ "${S3_ACCESS_KEY_ID}" = "NONE" ]; then
    echo "You need to set the S3_ACCESS_KEY_ID environment variable."
    exit 1
    fi

    if [ "${S3_SECRET_ACCESS_KEY}" = "NONE" ]; then
    echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
    exit 1
    fi

    if [ "${S3_BUCKET}" = "NONE" ]; then
    echo "You need to set the S3_BUCKET environment variable."
    exit 1
    fi

    if [ "${S3_PREFIX}" = "NONE" ]; then
    echo "You need to set the S3_PREFIX environment variable."
    exit 1
    fi

    if [ "${S3_ENDPOINT}" == "NONE" ]; then
    AWS_ARGS=""
    else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
    fi

    # env vars needed for aws tools
    export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
    export AWS_DEFAULT_REGION=$S3_REGION


}



