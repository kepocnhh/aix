#!/usr/local/bin/bash

JSON_INPUT="$(cat)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2
 echo '{"continue":false}'; exit 1
elif -z "${JSON_INPUT}"; then
 echo 'JSON input is empty!' >&2
 echo '{"continue":false}'; exit 1
fi

CURSOR_CONVERSATION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2
 echo '{"continue":false}'; exit 1; fi

CURSOR_GENERATION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2
 echo '{"continue":false}'; exit 1; fi

CURSOR_PROMPT=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.prompt // ""')
if test -z "${CURSOR_PROMPT}"; then
 echo "No prompt!" >&2
 echo '{"continue":false}'; exit 1; fi

CURSOR_WORKDIR="$(pwd)"

ISSUER="${CURSOR_WORKDIR}/.excluded/yml/cursor"

if test -d "${ISSUER}"; then
 CURSOR_CONVERSATION_ID="${CURSOR_CONVERSATION_ID}" \
 CURSOR_GENERATION_ID="${CURSOR_GENERATION_ID}" \
 CURSOR_PROMPT="${CURSOR_PROMPT}" \
 yq -n -M -o yml '{
   "session_id": strenv(CURSOR_CONVERSATION_ID),
   "turn_id": strenv(CURSOR_GENERATION_ID),
   "prompt": strenv(CURSOR_PROMPT)
  }' > "${ISSUER}/cursor-${CURSOR_CONVERSATION_ID}-${CURSOR_GENERATION_ID}.yml"
fi

echo '{"continue":true}'
