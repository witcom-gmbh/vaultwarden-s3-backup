#!/bin/bash

. ./includes.sh

function backup_init() {
    NOW="$(date +"${BACKUP_FILE_DATE_FORMAT}")"
    # backup vaultwarden database file
    BACKUP_FILE_DB="${BACKUP_DIR}/db.sqlite3"
    # backup vaultwarden config file
    BACKUP_FILE_CONFIG="${BACKUP_DIR}/config.json"
    # backup vaultwarden rsakey files
    BACKUP_FILE_RSAKEY="${BACKUP_DIR}/rsakey.tar"
    # backup vaultwarden attachments directory
    BACKUP_FILE_ATTACHMENTS="${BACKUP_DIR}/attachments.tar"
    # backup vaultwarden sends directory
    BACKUP_FILE_SENDS="${BACKUP_DIR}/sends.tar"
    # backup temp file
    BACKUP_FILE_TEMP="${BACKUP_DIR}/backup.temp.tar"
    # backup gzip file
    BACKUP_FILE_GZIP="${BACKUP_DIR}/backup.${NOW}.tar.gz"
}

function backup_db() {
    echo "backup vaultwarden sqlite database"

    if [[ -f "${DATA_DB}" ]]; then
        sqlite3 "${DATA_DB}" ".backup '${BACKUP_FILE_DB}'"
    else
        echo "vaultwarden sqlite database not found, skipping"
    fi
}

function backup_config() {
    echo "backup vaultwarden config"

    if [[ -f "${DATA_CONFIG}" ]]; then
        cp -f "${DATA_CONFIG}" "${BACKUP_FILE_CONFIG}"
    else
        echo "vaultwarden config not found, skipping"
    fi
}

function backup_rsakey() {
    echo "backup vaultwarden rsakey ${DATA_RSAKEY_DIRNAME}"

    if [[ -d "${DATA_RSAKEY_DIRNAME}" ]]; then
        local FIND_RSAKEY=$(find "${DATA_RSAKEY_DIRNAME}" -name "${DATA_RSAKEY_BASENAME}*" | xargs -I {} basename {})
        local FIND_RSAKEY_COUNT=$(echo "${FIND_RSAKEY}" | wc -l)

        if [[ "${FIND_RSAKEY_COUNT}" -gt 0 ]]; then
            echo "${FIND_RSAKEY}" | tar -c -C "${DATA_RSAKEY_DIRNAME}" -f "${BACKUP_FILE_RSAKEY}" -T -
        else
            echo "vaultwarden rsakey not found, skipping"
        fi
    else
        echo "vaultwarden rsakey-directory not found, skipping"

    fi
}

function backup_attachments() {
    echo "backup vaultwarden attachments"

    if [[ -d "${DATA_ATTACHMENTS}" ]]; then
        tar -c -C "${DATA_ATTACHMENTS_DIRNAME}" -f "${BACKUP_FILE_ATTACHMENTS}" "${DATA_ATTACHMENTS_BASENAME}"

    else
        echo "vaultwarden attachments directory not found, skipping"
    fi
}

function backup_sends() {
    echo "backup vaultwarden sends"

    if [[ -d "${DATA_SENDS}" ]]; then
        tar -c -C "${DATA_SENDS_DIRNAME}" -f "${BACKUP_FILE_SENDS}" "${DATA_SENDS_BASENAME}"

    else
        echo "vaultwarden sends directory not found, skipping"
    fi
}

function backup_package() {

    echo "package backup file"

    UPLOAD_FILE="${BACKUP_FILE_GZIP}"
    tar -cf "${BACKUP_FILE_TEMP}" "${BACKUP_DIR}"/*
    gzip "${BACKUP_FILE_TEMP}"
    mv "${BACKUP_FILE_TEMP}.gz" "${BACKUP_FILE_GZIP}"

}

function backup() {

    backup_db
    backup_config
    backup_rsakey
    backup_attachments
    backup_sends

}

function upload() {


    #update lifecycle configuration
    sed "s/RETENTION/${RETENTION_DAYS}/g;" lifecycle.json.tmpl > lifecycle.json
    aws s3api put-bucket-lifecycle-configuration --bucket $S3_BUCKET --endpoint-url $S3_ENDPOINT --lifecycle-configuration file://lifecycle.json

    echo "Uploading dump to bucket $S3_BUCKET"
    aws s3 $AWS_ARGS cp ${BACKUP_FILE_GZIP} s3://$S3_BUCKET/$S3_PREFIX/ || exit 2

}

function cleanup() {
    /bin/rm -rf ${BACKUP_DIR}/*
}


init_env
cleanup
backup_init
backup
backup_package
upload
cleanup
