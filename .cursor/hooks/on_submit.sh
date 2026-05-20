#!/usr/local/bin/bash

AI_NAME='cursor'

JSON_INPUT="$(cat)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2
 echo '{"continue":false}'; exit 2
elif -z "${JSON_INPUT}"; then
 echo 'JSON input is empty!' >&2
 echo '{"continue":false}'; exit 2
fi

AI_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2
 echo '{"continue":false}'; exit 2; fi

AI_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2
 echo '{"continue":false}'; exit 2; fi

USER_PROMPT=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.prompt // ""')
if test -z "${USER_PROMPT}"; then
 echo "No prompt!" >&2
 echo '{"continue":false}'; exit 2; fi

AI_WORKDIR="$(pwd)"

ISSUER="${AI_WORKDIR}/.excluded/yml/${AI_NAME}"

if test -d "${ISSUER}"; then
 AI_SESSION_ID="${AI_SESSION_ID}" \
 AI_TURN_ID="${AI_TURN_ID}" \
 USER_PROMPT="${USER_PROMPT}" \
 yq -n -M -o yml '{
   "session_id": strenv(AI_SESSION_ID),
   "turn_id": strenv(AI_TURN_ID),
   "prompt": strenv(USER_PROMPT)
  }' > "${ISSUER}/${AI_NAME}-${AI_SESSION_ID}-${AI_TURN_ID}.yml"
fi

echo '{"continue":true}'
