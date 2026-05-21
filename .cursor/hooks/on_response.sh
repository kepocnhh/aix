#!/usr/local/bin/bash

AI_NAME='cursor'

FILE_DIR="$(TZ='utc' LC_ALL=C date +%Y/%m/%d)"

JSON_INPUT="$(cat)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2; exit 1
elif test -z "${JSON_INPUT}"; then
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

AI_RESPONSE=$(printf '%s' "${JSON_INPUT}" | yq -r -p=json -o=json '.text // ""')
if test -z "${AI_RESPONSE}"; then
 echo "No response!" >&2; exit 1; fi

ISSUER="${AI_WORKDIR}/.excluded/md/${AI_NAME}"

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 printf '%s' "${AI_RESPONSE}" > "${ISSUER}/${FILE_DIR}/${AI_NAME}-${POINTER}.md"
fi

ISSUER="${AI_WORKDIR}/.excluded/yml/${AI_NAME}/${AI_NAME}-${AI_SESSION_ID}-${AI_TURN_ID}.yml"

if test -f "${ISSUER}"; then
 ACTUAL_SESSION_ID=$(yq -r -p=yml -o=json .session_id "${ISSUER}")
 if [[ "${AI_SESSION_ID}" != "${ACTUAL_SESSION_ID}" ]]; then
  echo "Actual session id \"${ACTUAL_SESSION_ID}\", but expected \"${AI_SESSION_ID}\"!" >&2; exit 1; fi
 ACTUAL_TURN_ID=$(yq -r -p=yml -o=json .turn_id "${ISSUER}")
 if [[ "${AI_TURN_ID}" != "${ACTUAL_TURN_ID}" ]]; then
  echo "Actual turn id \"${ACTUAL_TURN_ID}\", but expected \"${AI_TURN_ID}\"!" >&2; exit 1; fi
 AI_RESPONSE="${AI_RESPONSE}" \
  yq -M -i -p yml -o yml '.response=strenv(AI_RESPONSE)' "${ISSUER}"
fi
