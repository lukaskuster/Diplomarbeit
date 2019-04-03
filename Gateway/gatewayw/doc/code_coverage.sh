#!/usr/bin/env bash


if [[ ! -e ${1}/coverage.log ]]; then
    mkdir -p ${1}
    touch ${1}/coverage.log
fi

docstr-coverage ../gateway > ${1}/coverage.log
TOTAL_COVERAGE=$(cat ${1}/coverage.log | grep 'Total docstring coverage' | grep -Eo '[0-9.]{1,4}')

COLOR=red

if [[ 1 -eq "$(echo "${TOTAL_COVERAGE} > 99" | bc)" ]]
then
    COLOR=brightgreen
elif [[ 1 -eq "$(echo "${TOTAL_COVERAGE} > 80" | bc)" ]]
then
    COLOR=green
elif [[ 1 -eq "$(echo "${TOTAL_COVERAGE} > 50" | bc)" ]]
then
    COLOR=yellowgreen
elif [[ 1 -eq "$(echo "${TOTAL_COVERAGE} > 40" | bc)" ]]
then
    COLOR=yellow
elif [[ 1 -eq "$(echo "${TOTAL_COVERAGE} > 20" | bc)" ]]
then
    COLOR=orange
fi;

curl https://img.shields.io/badge/documentation-${TOTAL_COVERAGE}%25-${COLOR}.svg --output ${1}/badge.svg