#!/usr/local/bin/bash

FILE_DIR="$(TZ='utc' date +%Y/%m/%d)"

JSON_INPUT="$(cat)"
CODEX_SESSION_ID=$(echo "${JSON_INPUT}" | yq .session_id)
CODEX_TURN_ID=$(echo "${JSON_INPUT}" | yq .turn_id)
CODEX_WORKDIR=$(echo "${JSON_INPUT}" | yq .cwd)
CODEX_TRANSCRIPT_PATH=$(echo "${JSON_INPUT}" | yq .transcript_path)
CODEX_RESPONSE=$(echo "${JSON_INPUT}" | yq .last_assistant_message)
POINTER="$(TZ='utc' date +%Y%m%d%H%M%S)-${CODEX_SESSION_ID:0:8}"

ISSUER='.excluded/md/codex'

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 echo "${CODEX_RESPONSE}" > "${ISSUER}/${FILE_DIR}/codex-${POINTER}.md"
else
 echo "No dir \"${ISSUER}\"."
fi

echo '{"continue":true}'
