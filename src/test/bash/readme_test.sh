#!/usr/local/bin/bash

ISSUER='build/yml/metadata.yml'
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!" >&2; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!" >&2; exit 1
fi

VERSION="$(yq -erM -p=yml -o=json .version "${ISSUER}")" || exit 1
REP_OWNER="$(yq -erM -p=yml -o=json .repository.owner "${ISSUER}")" || exit 1
REP_NAME="$(yq -erM -p=yml -o=json .repository.name "${ISSUER}")" || exit 1

ISSUER='README.md'
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!" >&2; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!" >&2; exit 1
fi

EXPECTED_TEXT="\`${VERSION}\`
| [GitHub](https://github.com/${REP_OWNER}/${REP_NAME}/releases/tag/${VERSION})"

ALL_TEXT="$(< "${ISSUER}")"
if [[ "${ALL_TEXT}" != *"${EXPECTED_TEXT}"* ]]; then
 echo "File \"${ISSUER}\" does not contain:
---
${EXPECTED_TEXT}
---" >&2; exit 1; fi
