#!/bin/bash
PORT=${PACTPORT:-8080}
pact-mock-service control-stop -p ${PORT}
