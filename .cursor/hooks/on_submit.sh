#!/usr/local/bin/bash

AI_NAME='cursor'

if test -z "${AI_WORKDIR}"; then
 echo 'No workdir!' >&2
 printf '{"continue":false}'; exit 2; fi

AI_WORKDIR="$(realpath "${AI_WORKDIR}" 2> /dev/null)"
if test $? != 0; then
 echo 'Realpath workdir error!' >&2
 printf '{"continue":false}'; exit 2
elif [[ ! -d "${AI_WORKDIR}" ]]; then
 echo "Workdir \"${AI_WORKDIR}\" error!" >&2
 printf '{"continue":false}'; exit 2
fi

JSON_INPUT="$(cat)"
if test $? -ne 0; then
 echo 'Could not get JSON input!' >&2
 printf '%s' '{"continue":false}'; exit 2
elif test -z "${JSON_INPUT}"; then
 echo 'JSON input is empty!' >&2
 printf '%s' '{"continue":false}'; exit 2
fi

AI_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .conversation_id)
if test $? -ne 0; then
 echo 'Could not get conversation ID!' >&2
 printf '%s' '{"continue":false}'; exit 2; fi

AI_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -eMr -p=json -o=json .generation_id)
if test $? -ne 0; then
 echo 'Could not get generation ID!' >&2
 printf '%s' '{"continue":false}'; exit 2; fi

USER_PROMPT=$(printf '%s' "${JSON_INPUT}" | yq -Mr -p=json -o=json '.prompt // ""')
if test -z "${USER_PROMPT}"; then
 echo 'No prompt!' >&2
 printf '%s' '{"continue":false}'; exit 2; fi

AI_TIMESTAMP=$(TZ='utc' LC_ALL=C date +%s%3N)

ISSUER="${AI_WORKDIR}/.excluded/json/${AI_NAME}"

if test -d "${ISSUER}"; then
 AI_SESSION_ID="${AI_SESSION_ID}" \
 AI_TURN_ID="${AI_TURN_ID}" \
 USER_PROMPT="${USER_PROMPT}" \
 AI_WORKDIR="${AI_WORKDIR}" \
 AI_TIMESTAMP="${AI_TIMESTAMP}" \
 yq -nM -p=json -o=json "{
   \"session_id\": strenv(AI_SESSION_ID),
   \"turn_id\": strenv(AI_TURN_ID),
   \"prompt\": strenv(USER_PROMPT),
   \"workdir\": strenv(AI_WORKDIR),
   \"timestamp\": ${AI_TIMESTAMP}
  }" > "${ISSUER}/${AI_NAME}-${AI_SESSION_ID}-${AI_TURN_ID}.json"
fi

printf '%s' '{"continue":true}'
