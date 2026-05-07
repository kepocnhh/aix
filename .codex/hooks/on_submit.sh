#!/usr/local/bin/bash

JSON_INPUT="$(cat)"

CODEX_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -e -r .session_id)
if test $? -ne 0; then
 echo 'Could not get session ID!' >&2
 echo '{"continue":false}'; exit 1; fi

CODEX_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -e -r .turn_id)
if test $? -ne 0; then
 echo 'Could not get turn ID!' >&2
 echo '{"continue":false}'; exit 1; fi

CODEX_WORKDIR=$(printf '%s' "${JSON_INPUT}" | yq -e -r .cwd)
if test $? -ne 0; then
 echo 'Could not get workdir!' >&2
 echo '{"continue":false}'; exit 1; fi

CODEX_WORKDIR="$(realpath "${CODEX_WORKDIR}")"
if test $? != 0; then
 echo "Realpath error!" >&2
 echo '{"continue":false}'; exit 1; fi

if [[ ! -d "${CODEX_WORKDIR}" ]]; then
 echo "Workdir \"${CODEX_WORKDIR}\" error!" >&2
 echo '{"continue":false}'; exit 1; fi

CODEX_PROMPT=$(printf '%s' "${JSON_INPUT}" | yq -r '.prompt // ""')
if test -z "${CODEX_PROMPT}"; then
 echo "No prompt!" >&2
 echo '{"continue":false}'; exit 1; fi

ISSUER="${CODEX_WORKDIR}/.excluded/yml/codex"

if test -d "${ISSUER}"; then
 CODEX_SESSION_ID="${CODEX_SESSION_ID}" \
 CODEX_TURN_ID="${CODEX_TURN_ID}" \
 CODEX_PROMPT="${CODEX_PROMPT}" \
 yq -n -M -o yml '{
   "session_id": strenv(CODEX_SESSION_ID),
   "turn_id": strenv(CODEX_TURN_ID),
   "prompt": strenv(CODEX_PROMPT)
  }' > "${ISSUER}/codex-${CODEX_SESSION_ID}-${CODEX_TURN_ID}.yml"
else
 echo "No dir \"${ISSUER}\"." >&2
fi

echo '{"continue":true}'
