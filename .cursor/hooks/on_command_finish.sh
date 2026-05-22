#!/usr/local/bin/bash

AI_NAME='cursor'

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

AI_WORKDIR="$(pwd)"
if test $? != 0; then
 echo "Get workdir error!" >&2; exit 1
elif [[ ! -d "${AI_WORKDIR}" ]]; then
 echo "Workdir \"${AI_WORKDIR}\" error!" >&2; exit 1
fi

AI_COMMAND_WORKDIR=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.tool_input.cwd // ""')
if test $? -ne 0; then
 echo 'Could not get workdir!' >&2; exit 1; fi

if test -n "${AI_COMMAND_WORKDIR}"; then
 AI_COMMAND_WORKDIR="$(realpath "${AI_COMMAND_WORKDIR}")"
 if test $? != 0; then
  echo "Realpath command error!" >&2; exit 1
 elif [[ ! -d "${AI_COMMAND_WORKDIR}" ]]; then
  echo "Workdir \"${AI_COMMAND_WORKDIR}\" command error!" >&2; exit 1
 fi
fi

AI_COMMAND_NAME=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .tool_name)
if test $? -ne 0; then
 echo 'Could not get command name!' >&2; exit 1
elif test -z "${AI_COMMAND_NAME}"; then
 echo 'Command name is empty!' >&2; exit 1
fi

AI_COMMAND_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .tool_use_id)
if test $? -ne 0; then
 echo 'Could not get command ID!' >&2; exit 1
elif test -z "${AI_COMMAND_ID}"; then
 echo 'Command ID is empty!' >&2; exit 1
fi

if test "${AI_COMMAND_NAME}" == 'Shell'; then
 AI_COMMAND_SHELL=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.tool_input.command // ""')
 if test $? -ne 0; then
  echo 'Could not get command!' >&2; exit 1
 elif test -z "${AI_COMMAND_SHELL}"; then
  echo 'Command is empty!' >&2; exit 1
 fi
fi

AI_COMMAND_OUTPUT=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.tool_output // null')
if test $? -ne 0; then
 echo 'Could not get command output!' >&2; exit 1
elif test -z "${AI_COMMAND_OUTPUT}"; then
 echo 'Command output is empty!' >&2; exit 1
fi

ISSUER="${AI_WORKDIR}/.excluded/yml/${AI_NAME}/${AI_NAME}-${AI_SESSION_ID}-${AI_TURN_ID}.yml"

if test -f "${ISSUER}"; then
 ACTUAL_SESSION_ID=$(yq -r -p=yml -o=json .session_id "${ISSUER}")
 if [[ "${AI_SESSION_ID}" != "${ACTUAL_SESSION_ID}" ]]; then
  echo "Actual session id \"${ACTUAL_SESSION_ID}\", but expected \"${AI_SESSION_ID}\"!" >&2; exit 1; fi
 ACTUAL_TURN_ID=$(yq -r -p=yml -o=json .turn_id "${ISSUER}")
 if [[ "${AI_TURN_ID}" != "${ACTUAL_TURN_ID}" ]]; then
  echo "Actual turn id \"${ACTUAL_TURN_ID}\", but expected \"${AI_TURN_ID}\"!" >&2; exit 1; fi
 ACTUAL_COMMAND_NAME=$(yq -r -p=yml -o=json ".commands.${AI_COMMAND_ID}.name" "${ISSUER}")
 if [[ "${AI_COMMAND_NAME}" != "${ACTUAL_COMMAND_NAME}" ]]; then
  echo "Actual command name \"${ACTUAL_COMMAND_NAME}\", but expected \"${AI_COMMAND_NAME}\"!" >&2; exit 1; fi
 if test "${AI_COMMAND_NAME}" == 'Shell'; then
  ACTUAL_COMMAND_SHELL=$(yq -r -p=yml -o=json ".commands.${AI_COMMAND_ID}.shell" "${ISSUER}")
  if [[ "${AI_COMMAND_SHELL}" != "${ACTUAL_COMMAND_SHELL}" ]]; then
   echo "Actual command shell \"${ACTUAL_COMMAND_SHELL}\", but expected \"${AI_COMMAND_SHELL}\"!" >&2; exit 1;fi
 fi
fi
