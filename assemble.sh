#!/usr/local/bin/bash

REP_OWNER='kepocnhh'
REP_NAME='aix'
VERSION='0.0.3'

mkdir 'build'
mkdir -p 'build/yml'
ISSUER='build/yml/metadata.yml'
echo "repository:
 owner: '${REP_OWNER}'
 name: '${REP_NAME}'
version: '${VERSION}'" > "${ISSUER}"

if [[ ! -s 'LICENSE' ]]; then
 echo 'No license!' >&2; exit 1; fi

if [[ ! -s 'README.md' ]]; then
 echo 'No readme!' >&2; exit 1; fi

mkdir -p 'build/zip'
ISSUER="build/zip/${REP_NAME}-${VERSION}.zip"
zip -r "${ISSUER}" '.codex' '.cursor' 'LICENSE' 'README.md'
if test $? -ne 0; then
 echo 'Zip error!' >&2; exit 1; fi
