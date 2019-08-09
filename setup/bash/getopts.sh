#!/bin/bash
while getopts p: option
do
case "${option}"
in
p) PROJECT=${OPTARG};;
esac
done

if [ "${PROJECT}" = "" ]; then
    PROJECT="main"
fi