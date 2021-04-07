#!/usr/bin/env bash

docker build --build-arg BUNDLE_WITHOUT=development --build-arg VROOM_VERSION=v1.5.0 --build-arg OPTIMIZER_ORTOOLS_VERSION=${OPTIMIZER_ORTOOLS_VERSION} -f docker/Dockerfile -t registry.test.com/mapotempo/optimizer-api:latest .
