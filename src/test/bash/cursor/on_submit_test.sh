#!/usr/local/bin/bash

SCRIPT=".cursor/hooks/on_submit.sh"

if [[ ! -e "${SCRIPT}" ]]; then
 echo "No file \"${SCRIPT}\"!" >&2; exit 1
elif [[ -L "${SCRIPT}" ]]; then
 echo "The \"${SCRIPT}\" is symlink!" >&2; exit 1
elif [[ ! -f "${SCRIPT}" ]]; then
 echo "Not a regular file \"${SCRIPT}\"!" >&2; exit 1
elif [[ ! -s "${SCRIPT}" ]]; then
 echo "File \"${SCRIPT}\" is empty!" >&2; exit 1
elif [[ ! -x "${SCRIPT}" ]]; then
 echo "File \"${SCRIPT}\" is not executable!" >&2; exit 1
fi

STDOUT="$(mktemp)"
STDERR="$(mktemp)"

"${SCRIPT}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != 'No workdir!'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi

:> "${STDOUT}"
:> "${STDERR}"

TMP_DIR="$(realpath "$(mktemp -d)")"
rm -rf "${TMP_DIR}"
AI_WORKDIR="${TMP_DIR}" "${SCRIPT}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != "Workdir \"${TMP_DIR}\" error!"; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi

:> "${STDOUT}"
:> "${STDERR}"

TMP_DIR="$(mktemp)"
rm "${TMP_DIR}"
ln -sf "${TMP_DIR}" "${TMP_DIR}"
AI_WORKDIR="${TMP_DIR}" "${SCRIPT}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != 'Realpath workdir error!'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi

:> "${STDOUT}"
:> "${STDERR}"

TMP_DIR="$(mktemp -d)"
AI_WORKDIR="${TMP_DIR}" "${SCRIPT}" <"${TMP_DIR}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != 'Could not get JSON input!'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
rm -rf "${TMP_DIR}"

:> "${STDOUT}"
:> "${STDERR}"

TMP_DIR="$(mktemp -d)"
printf '' | AI_WORKDIR="${TMP_DIR}" "${SCRIPT}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != 'JSON input is empty!'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
rm -rf "${TMP_DIR}"

:> "${STDOUT}"
:> "${STDERR}"

TMP_DIR="$(mktemp -d)"
JSON_INPUT='{}'
printf "${JSON_INPUT}" | AI_WORKDIR="${TMP_DIR}" "${SCRIPT}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != 'Could not get conversation ID!'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
rm -rf "${TMP_DIR}"

:> "${STDOUT}"
:> "${STDERR}"

TMP_DIR="$(mktemp -d)"
JSON_INPUT='{"conversation_id":"foo"}'
printf "${JSON_INPUT}" | AI_WORKDIR="${TMP_DIR}" "${SCRIPT}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != 'Could not get generation ID!'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
rm -rf "${TMP_DIR}"

echo 'Not implemented!' >&2; exit 1

rm "${STDOUT}"
rm "${STDERR}"
