#!/bin/bash
PORT=${PACTPORT:-8080}
mkdir -p "${SRCROOT}/tmp"
nohup pact-mock-service control-start -l "${SRCROOT}/tmp" --pact-dir "${SRCROOT}/pacts" -p ${PORT} > ${SRCROOT}/tmp/nohup.out 2>&1 &
