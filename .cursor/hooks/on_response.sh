#!/usr/local/bin/bash

AI_NAME='cursor'

FILE_DIR="$(TZ='utc' LC_ALL=C date +%Y/%m/%d)"

JSON_INPUT="$(cat)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2; exit 1
elif -z "${JSON_INPUT}"; then
 echo 'JSON input is empty!' >&2; exit 1
fi

AI_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2; exit 1; fi

AI_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2; exit 1; fi

POINTER="$(TZ='utc' LC_ALL=C date +%Y%m%d%H%M%S)-${AI_SESSION_ID:0:8}"

AI_WORKDIR="$(pwd)"

ISSUER="${AI_WORKDIR}/.excluded/json/${AI_NAME}"

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 printf '%s' "${JSON_INPUT}" > "${ISSUER}/${FILE_DIR}/${AI_NAME}-${POINTER}.json"
fi

ISSUER="${AI_WORKDIR}/.excluded/md/${AI_NAME}"

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 printf '%s' "${JSON_INPUT}" | yq -r -p=json -o=json .text > "${ISSUER}/${FILE_DIR}/${AI_NAME}-${POINTER}.md"
fi
