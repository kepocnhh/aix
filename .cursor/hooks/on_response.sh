#!/usr/local/bin/bash

AI_NAME='cursor'

if test -z "${AI_WORKDIR}"; then
 echo 'No workdir!' >&2; exit 1; fi

AI_WORKDIR="$(realpath "${AI_WORKDIR}" 2> /dev/null)"
if test $? != 0; then
 echo 'Realpath workdir error!' >&2; exit 1
elif [[ ! -d "${AI_WORKDIR}" ]]; then
 echo "Workdir \"${AI_WORKDIR}\" error!" >&2; exit 1
fi

FILE_DIR="$(TZ='utc' LC_ALL=C date +%Y/%m/%d)"

JSON_INPUT="$(cat 2> /dev/null)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2; exit 1
elif test -z "${JSON_INPUT}"; then
 echo 'JSON input is empty!' >&2; exit 1
fi

AI_SESSION_ID=$(printf "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id 2> /dev/null)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2; exit 1; fi

AI_TURN_ID=$(printf "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id 2> /dev/null)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2; exit 1; fi

AI_RESPONSE=$(printf "${JSON_INPUT}" | yq -r -p=json -o=json '.text // ""')
if test -z "${AI_RESPONSE}"; then
 echo 'No response!' >&2; exit 1; fi

ISSUER="${AI_WORKDIR}/.excluded/md/${AI_NAME}"

POINTER="$(TZ='utc' LC_ALL=C date +%Y%m%d%H%M%S)-${AI_SESSION_ID:0:8}"

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 printf "${AI_RESPONSE}" > "${ISSUER}/${FILE_DIR}/${AI_NAME}-${POINTER}.md"
fi

ISSUER="${AI_WORKDIR}/.excluded/json/${AI_NAME}/${AI_NAME}-${AI_SESSION_ID}-${AI_TURN_ID}.json"

if test -f "${ISSUER}"; then
 ACTUAL_SESSION_ID=$(yq -r -p=json -o=json .session_id "${ISSUER}")
 if [[ "${AI_SESSION_ID}" != "${ACTUAL_SESSION_ID}" ]]; then
  echo "Actual session id \"${ACTUAL_SESSION_ID}\", but expected \"${AI_SESSION_ID}\"!" >&2; exit 1; fi
 ACTUAL_TURN_ID=$(yq -r -p=json -o=json .turn_id "${ISSUER}")
 if [[ "${AI_TURN_ID}" != "${ACTUAL_TURN_ID}" ]]; then
  echo "Actual turn id \"${ACTUAL_TURN_ID}\", but expected \"${AI_TURN_ID}\"!" >&2; exit 1; fi
 STR_VALUE="${AI_RESPONSE}" \
  yq -i -p=json -o=json '.response=strenv(STR_VALUE)' "${ISSUER}"
fi
