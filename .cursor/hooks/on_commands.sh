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
 echo 'Could not get conversation ID!' >&2
 echo '{"permission":"deny"}'; exit 2; fi

AI_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2
 echo '{"permission":"deny"}'; exit 2; fi

AI_WORKDIR="$(pwd)"
if test $? != 0; then
 echo "Get workdir error!" >&2
 echo '{"permission":"deny"}'; exit 2
elif [[ ! -d "${AI_WORKDIR}" ]]; then
 echo "Workdir \"${AI_WORKDIR}\" error!" >&2
 echo '{"permission":"deny"}'; exit 2
fi

AI_COMMAND_WORKDIR=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.cwd // ""')
if test $? -ne 0; then
 echo 'Could not get workdir!' >&2
 echo '{"permission":"deny"}'; exit 2; fi

if test -n "${AI_COMMAND_WORKDIR}"; then
 AI_COMMAND_WORKDIR="$(realpath "${AI_COMMAND_WORKDIR}")"
 if test $? != 0; then
  echo "Realpath command error!" >&2
  echo '{"permission":"deny"}'; exit 2
 elif [[ ! -d "${AI_COMMAND_WORKDIR}" ]]; then
  echo "Workdir \"${AI_COMMAND_WORKDIR}\" command error!" >&2
  echo '{"permission":"deny"}'; exit 2
 fi
fi

AI_COMMAND=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.command // ""')
if test $? -ne 0; then
 echo 'Could not get command!' >&2
 echo '{"permission":"deny"}'; exit 2
elif test -z "${AI_COMMAND}"; then
 echo 'Command is empty!' >&2
 echo '{"permission":"deny"}'; exit 2
fi

AI_COMMAND_ID="$(xxd -l 4 -p /dev/urandom)"
if test $? -ne 0; then
 echo 'Could not get command ID!' >&2
 echo '{"permission":"deny"}'; exit 2
elif [[ "${#AI_COMMAND_ID}" != '4' ]]; then
 echo 'Wrong command ID!' >&2
 echo '{"permission":"deny"}'; exit 2
fi

ISSUER="${AI_WORKDIR}/.excluded/yml/${AI_NAME}/${AI_NAME}-${AI_SESSION_ID}-${AI_TURN_ID}.yml"

if test -f "${ISSUER}"; then
 ACTUAL_SESSION_ID=$(yq -r -p=yml -o=json .session_id "${ISSUER}")
 if [[ "${AI_SESSION_ID}" != "${ACTUAL_SESSION_ID}" ]]; then
  echo "Actual session id \"${ACTUAL_SESSION_ID}\", but expected \"${AI_SESSION_ID}\"!" >&2
  echo '{"permission":"deny"}'; exit 2; fi
 ACTUAL_TURN_ID=$(yq -r -p=yml -o=json .turn_id "${ISSUER}")
 if [[ "${AI_TURN_ID}" != "${ACTUAL_TURN_ID}" ]]; then
  echo "Actual turn id \"${ACTUAL_TURN_ID}\", but expected \"${AI_TURN_ID}\"!" >&2
  echo '{"permission":"deny"}'; exit 2; fi
 AI_COMMAND="${AI_COMMAND}" \
  yq -i -p=yml -o=yml ".commands.${AI_COMMAND_ID}.value=strenv(AI_COMMAND)" "${ISSUER}"
fi

if [[ "${AI_COMMAND}" =~ \>|\>\> ]]; then
 echo '{"permission":"ask"}'; exit 0; fi

if test -f "${ISSUER}"; then
 yq -i -p=yml -o=yml ".commands.${AI_COMMAND_ID}.allowed=true" "${ISSUER}"
fi

echo '{"permission":"allow"}'
