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

POINTER="$(TZ='utc' LC_ALL=C date +%s%N)"
printf '%s' "${JSON_INPUT}" > "/tmp/commands-${POINTER}.json" # todo

AI_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2
 echo '{"permission":"deny"}'; exit 2; fi

AI_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2
 echo '{"permission":"deny"}'; exit 2; fi

AI_WORKDIR=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json .cwd)
if test $? -ne 0; then
 echo 'Could not get workdir!' >&2
 echo '{"permission":"deny"}'; exit 2; fi

AI_WORKDIR="$(realpath "${AI_WORKDIR}")"
if test $? != 0; then
 echo "Realpath error!" >&2
 echo '{"permission":"deny"}'; exit 2; fi

if [[ ! -d "${AI_WORKDIR}" ]]; then
 echo "Workdir \"${AI_WORKDIR}\" error!" >&2
 echo '{"permission":"deny"}'; exit 2; fi

echo '{"permission":"allow"}'
