#!/usr/local/bin/bash

AI_NAME='cursor'

JSON_INPUT="$(cat)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2
 echo '{"permission":"deny"}'; exit 2
elif test -z "${JSON_INPUT}"; then
 echo 'JSON input is empty!' >&2
 echo '{"permission":"deny"}'; exit 2
fi

AI_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2; exit 1; fi

AI_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2; exit 1; fi

POINTER="$(TZ='utc' LC_ALL=C date +%s%N)-${AI_SESSION_ID:0:4}-${AI_TURN_ID:0:4}"

printf '%s' "${JSON_INPUT}" > "/tmp/${AI_NAME}-${POINTER}-command.json"

echo '{"permission":"allow"}'
