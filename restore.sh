#!/bin/bash

. ./includes.sh

function check() {

    if [[ ! -d "${DATA_DIR}" ]]; then
        echo "vaultwarden data directory ${DATA_DIR} not found, unable to restore"
        exit 1;
    fi
}

function get_backup() {

    list=$(aws s3 ls s3://$S3_BUCKET/$S3_PREFIX/ $AWS_ARGS | grep -wv PRE | sort -r | awk '{ print $4 }')
    echo "Select a backup to restore" 
    select file in $list
    do
        echo "Selected $file";
        break;
    done
    echo "Fetching ${file} from S3"
    aws s3 cp s3://$S3_BUCKET/$S3_PREFIX/$file ${BACKUP_DIR}/restore.tar.gz $AWS_ARGS
}

function restore_backup() {
    cd ${BACKUP_DIR}
    tar -xzf restore.tar.gz --strip-components=1
    # if backup contains database -> restore it
    BACKUP_FILE_DB="${BACKUP_DIR}/db.sqlite3"
    if [[ -f "${BACKUP_FILE_DB}" ]]; then
      echo "Restoring database"
      cp -f ${BACKUP_FILE_DB} ${DATA_DB}
    fi

    # vaultwarden config file
    BACKUP_FILE_CONFIG="${BACKUP_DIR}/config.json"
    if [[ -f "${BACKUP_FILE_CONFIG}" ]]; then
      echo "Restoring config file"
      cp -f ${BACKUP_FILE_CONFIG} ${DATA_CONFIG}
    fi

    # vaultwarden rsakey files
    BACKUP_FILE_RSAKEY="${BACKUP_DIR}/rsakey.tar"
    if [[ -f "${BACKUP_FILE_RSAKEY}" ]]; then
        echo "Restoring RSA keys"
        # remove old stuff
        rm -f ${DATA_RSAKEY}*
        #extract stuff
        tar -C ${DATA_RSAKEY_DIRNAME} -xf rsakey.tar
    fi

    # backup vaultwarden attachments directory
    BACKUP_FILE_ATTACHMENTS="${BACKUP_DIR}/attachments.tar"
    if [[ -f "${BACKUP_FILE_ATTACHMENTS}" ]]; then
        echo "Restoring attachments"
        # remove old stuff
        rm -rf ${DATA_ATTACHMENTS}
        #extract stuff
        tar -C ${DATA_ATTACHMENTS_DIRNAME} -xf ${BACKUP_FILE_ATTACHMENTS}
    fi

    # backup vaultwarden sends directory
    BACKUP_FILE_SENDS="${BACKUP_DIR}/sends.tar" 
    if [[ -f "${BACKUP_FILE_SENDS}" ]]; then
        echo "Restoring sends"
        # remove old stuff
        rm -rf ${DATA_SENDS}
        #extract stuff
        tar -C ${DATA_SENDS_DIRNAME} -xf ${BACKUP_FILE_SENDS}
    fi

    cd /app

}

function cleanup() {
    /bin/rm -rf ${BACKUP_DIR}/*
}

init_env
check
cleanup
get_backup
restore_backup
cleanup

