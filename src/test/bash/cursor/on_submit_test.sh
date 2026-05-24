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

AI_WORKDIR='/foo'
AI_WORKDIR="${AI_WORKDIR}" "${SCRIPT}" >"${STDOUT}" 2>"${STDERR}"; CODE=$?
if test "${CODE}" != '2'; then
 echo "Code(${CODE}) error!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDOUT}")"
if test "${ACTUAL_VALUE}" != '{"continue":false}'; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi
ACTUAL_VALUE="$(<"${STDERR}")"
if test "${ACTUAL_VALUE}" != "Workdir \"${AI_WORKDIR}\" error!"; then
 echo "Actual value(${#ACTUAL_VALUE}) is: \"${ACTUAL_VALUE}\"!" >&2; exit 1; fi

echo 'Not implemented!' >&2; exit 1
