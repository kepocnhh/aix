#!/usr/local/bin/bash

FILE_DIR="$(TZ='utc' LC_ALL=C date +%Y/%m/%d)"

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

POINTER="$(TZ='utc' LC_ALL=C date +%Y%m%d%H%M%S)-${CODEX_SESSION_ID:0:8}"

ISSUER="${CODEX_WORKDIR}/.excluded/json/codex"

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 printf '%s' "${JSON_INPUT}" | yq -M -o json > "${ISSUER}/${FILE_DIR}/codex-${POINTER}.json"
else
 echo "No dir \"${ISSUER}\"." >&2
fi

CODEX_TRANSCRIPT_PATH=$(printf '%s' "${JSON_INPUT}" | yq -r '.transcript_path // ""')
if [[ ! -f "${CODEX_TRANSCRIPT_PATH}" ]]; then
 echo "No file \"${CODEX_TRANSCRIPT_PATH}\"!" >&2
 echo '{"continue":false}'; exit 1
elif [[ ! -s "${CODEX_TRANSCRIPT_PATH}" ]]; then
 echo "File \"${CODEX_TRANSCRIPT_PATH}\" is empty!" >&2
 echo '{"continue":false}'; exit 1; fi

ISSUER="${CODEX_WORKDIR}/.excluded/jsonl/codex"

if test -d "${ISSUER}"; then
 cp "${CODEX_TRANSCRIPT_PATH}" "${ISSUER}/codex-${CODEX_SESSION_ID}.jsonl"
else
 echo "No dir \"${ISSUER}\"." >&2
fi

CODEX_RESPONSE=$(printf '%s' "${JSON_INPUT}" | yq -r '.last_assistant_message // ""')

if test -z "${CODEX_RESPONSE}"; then
 echo "No response!" >&2
 echo '{"continue":false}'; exit 1; fi

ISSUER="${CODEX_WORKDIR}/.excluded/md/codex"

if test -d "${ISSUER}"; then
 mkdir -p "${ISSUER}/${FILE_DIR}"
 printf '%s' "${CODEX_RESPONSE}" > "${ISSUER}/${FILE_DIR}/codex-${POINTER}.md"
else
 echo "No dir \"${ISSUER}\"." >&2
fi

ISSUER="${CODEX_WORKDIR}/.excluded/yml/codex/codex-${CODEX_SESSION_ID}-${CODEX_TURN_ID}.yml"

if test -f "${ISSUER}"; then
 ACTUAL_SESSION_ID=$(printf '%s' "${JSON_INPUT}" | yq -e -r .session_id)
 if [[ "${CODEX_SESSION_ID}" != "${ACTUAL_SESSION_ID}" ]]; then
  echo "Actual session id \"${ACTUAL_SESSION_ID}\", but expected \"${CODEX_SESSION_ID}\"!" >&2
  echo '{"continue":false}'; exit 1; fi
 ACTUAL_TURN_ID=$(printf '%s' "${JSON_INPUT}" | yq -e -r .turn_id)
 if [[ "${CODEX_TURN_ID}" != "${ACTUAL_TURN_ID}" ]]; then
  echo "Actual turn id \"${ACTUAL_TURN_ID}\", but expected \"${CODEX_TURN_ID}\"!" >&2
  echo '{"continue":false}'; exit 1; fi
 CODEX_RESPONSE="${CODEX_RESPONSE}" \
  yq -M -i -p yml -o yml '.last_assistant_message=strenv(CODEX_RESPONSE)' "${ISSUER}"
else
 echo "No file \"${ISSUER}\"." >&2
fi

echo '{"continue":true}'
