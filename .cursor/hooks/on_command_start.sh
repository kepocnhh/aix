#!/usr/local/bin/bash

AI_NAME='cursor'

if test -z "${AI_WORKDIR}"; then
 echo 'No workdir!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2; fi

AI_WORKDIR="$(realpath "${AI_WORKDIR}")"
if test $? != 0; then
 echo 'Realpath workdir error!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2
elif [[ ! -d "${AI_WORKDIR}" ]]; then
 echo "Workdir \"${AI_WORKDIR}\" error!" >&2
 printf '%s' '{"permission":"deny"}'; exit 2
fi

JSON_INPUT="$(cat)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2
elif test -z "${JSON_INPUT}"; then
 echo 'JSON input is empty!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2
fi

AI_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2; fi

AI_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2; fi

AI_COMMAND_NAME=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .tool_name)
if test $? -ne 0; then
 echo 'Could not get command name!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2
elif test -z "${AI_COMMAND_NAME}"; then
 echo 'Command name is empty!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2
fi

AI_COMMAND_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .tool_use_id)
if test $? -ne 0; then
 echo 'Could not get command ID!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2
elif test -z "${AI_COMMAND_ID}"; then
 echo 'Command ID is empty!' >&2
 printf '%s' '{"permission":"deny"}'; exit 2
fi

AI_COMMAND_TIMESTAMP=$(TZ='utc' LC_ALL=C date +%s%3N)

ISSUER="${AI_WORKDIR}/.excluded/json/${AI_NAME}/${AI_NAME}-${AI_SESSION_ID}-${AI_TURN_ID}.json"

if test -f "${ISSUER}"; then
 ACTUAL_SESSION_ID=$(yq -r -p=json -o=json .session_id "${ISSUER}")
 if [[ "${AI_SESSION_ID}" != "${ACTUAL_SESSION_ID}" ]]; then
  echo "Actual session id \"${ACTUAL_SESSION_ID}\", but expected \"${AI_SESSION_ID}\"!" >&2
  printf '%s' '{"permission":"deny"}'; exit 2; fi
 ACTUAL_TURN_ID=$(yq -r -p=json -o=json .turn_id "${ISSUER}")
 if [[ "${AI_TURN_ID}" != "${ACTUAL_TURN_ID}" ]]; then
  echo "Actual turn id \"${ACTUAL_TURN_ID}\", but expected \"${AI_TURN_ID}\"!" >&2
  printf '%s' '{"permission":"deny"}'; exit 2; fi
 yq -i -p=json -o=json ".commands.${AI_COMMAND_ID}.timestamp=${AI_COMMAND_TIMESTAMP}" "${ISSUER}"
 STR_VALUE="${AI_COMMAND_NAME}" \
  yq -i -p=json -o=json ".commands.${AI_COMMAND_ID}.name=strenv(STR_VALUE)" "${ISSUER}"
fi

case "${AI_COMMAND_NAME}" in
 'Shell')
  AI_COMMAND_SHELL=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.tool_input.command // ""')
  if test $? -ne 0; then
   echo 'Could not get command shell!' >&2
   printf '%s' '{"permission":"deny"}'; exit 2
  elif test -z "${AI_COMMAND_SHELL}"; then
   echo 'Command shell is empty!' >&2
   printf '%s' '{"permission":"deny"}'; exit 2
  fi
  AI_COMMAND_WORKDIR=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.tool_input.cwd // ""')
  if test $? -ne 0; then
   echo 'Could not get command workdir!' >&2
   printf '%s' '{"permission":"deny"}'; exit 2
  elif test -n "${AI_COMMAND_WORKDIR}"; then
   AI_COMMAND_WORKDIR="$(realpath "${AI_COMMAND_WORKDIR}")"
   if test $? != 0; then
    echo 'Realpath command workdir error!' >&2
    printf '%s' '{"permission":"deny"}'; exit 2
   elif [[ ! -d "${AI_COMMAND_WORKDIR}" ]]; then
    echo "Workdir \"${AI_COMMAND_WORKDIR}\" command error!" >&2
    printf '%s' '{"permission":"deny"}'; exit 2
   fi
  fi;;
 'Read'|'Write'|'StrReplace'|'Delete'|'Grep')
  AI_COMMAND_FILE_PATH=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .tool_input.file_path)
  if test $? -ne 0; then
   echo 'Could not get command file path!' >&2
   printf '%s' '{"permission":"deny"}'; exit 2; fi
  AI_COMMAND_FILE_PATH="$(realpath -m "${AI_COMMAND_FILE_PATH}")"
  if test $? != 0; then
   echo 'Realpath command file error!' >&2
   printf '%s' '{"permission":"deny"}'; exit 2; fi;;
esac

if test -f "${ISSUER}"; then
 if test -n "${AI_COMMAND_WORKDIR}"; then
  STR_VALUE="${AI_COMMAND_WORKDIR}" \
   yq -i -p=json -o=json ".commands.${AI_COMMAND_ID}.workdir=strenv(STR_VALUE)" "${ISSUER}"; fi
 if test -n "${AI_COMMAND_SHELL}"; then
  STR_VALUE="${AI_COMMAND_SHELL}" \
   yq -i -p=json -o=json ".commands.${AI_COMMAND_ID}.shell=strenv(STR_VALUE)" "${ISSUER}"; fi
 if test -n "${AI_COMMAND_FILE_PATH}"; then
  STR_VALUE="${AI_COMMAND_FILE_PATH}" \
   yq -i -p=json -o=json ".commands.${AI_COMMAND_ID}.file=strenv(STR_VALUE)" "${ISSUER}"; fi
fi

if test -n "${AI_COMMAND_FILE_PATH}"; then
 if [[ "${AI_COMMAND_FILE_PATH}" != "${AI_WORKDIR}"/* ]]; then
  if [[ "${AI_COMMAND_NAME}" != 'Grep' || "${AI_COMMAND_FILE_PATH}" != "${AI_WORKDIR}" ]]; then
   echo "Workdir \"${AI_WORKDIR}\" does not contain \"${AI_COMMAND_FILE_PATH}\"!" >&2
   printf '%s' '{"permission":"deny"}'; exit 2; fi
 fi
fi

printf '%s' '{"permission":"allow"}'
