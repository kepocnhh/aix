#!/usr/local/bin/bash

FILE_DIR="$(TZ='utc' date +%Y/%m/%d)"

JSON_INPUT="$(cat)"
CONVERSATION_ID=$(echo "${JSON_INPUT}" | yq .conversation_id)
POINTER="$(TZ='utc' date +%Y%m%d%H%M%S)-${CONVERSATION_ID:0:8}"

ISSUER='.excluded/json/cursor'

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 echo "${JSON_INPUT}" | yq > "${ISSUER}/${FILE_DIR}/cursor-${POINTER}.json"
else
 echo "No dir \"${ISSUER}\"."
fi

ISSUER='.excluded/md/cursor'

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 echo "${JSON_INPUT}" | yq .text > "${ISSUER}/${FILE_DIR}/cursor-${POINTER}.md"
else
 echo "No dir \"${ISSUER}\"."
fi
