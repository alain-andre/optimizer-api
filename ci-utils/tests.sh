#!/usr/bin/env bash

docker run -id --name redis -p 6379:6379 -v $(pwd)/redis:/data redis:${REDIS_VERSION:-3.2-alpine} redis-server --appendonly yes

TEST_ENV=''
TEST_LOG_LEVEL=info
DOCKER_SERVICE_NAME=optimizer_api

case "$1" in
  'basis')
    TEST_ENV='TRAVIS=true COV=false SKIP_DICHO=true SKIP_JSPRIT=true SKIP_REAL_CASES=true SKIP_SCHEDULING=true SKIP_SPLIT_CLUSTERING=true'
    ;;
  'dicho')
    TEST_ENV="TRAVIS=true COV=${TEST_COVERAGE} LOG_LEVEL=${TEST_LOG_LEVEL} TEST=test/lib/heuristics/dichotomious_test.rb"
    ;;
  'real')
    TEST_ENV="TRAVIS=true COV=${TEST_COVERAGE} LOG_LEVEL=${TEST_LOG_LEVEL} TEST=test/real_cases_test.rb"
    ;;
  'real_scheduling')
    TEST_ENV="TRAVIS=true COV=${TEST_COVERAGE} LOG_LEVEL=${TEST_LOG_LEVEL} TEST=test/real_cases_scheduling_test.rb"
    ;;
  'real_scheduling_solver')
    TEST_ENV="TRAVIS=true COV=${TEST_COVERAGE} LOG_LEVEL=${TEST_LOG_LEVEL} TEST=test/real_cases_scheduling_solver_test.rb"
    ;;
  'scheduling')
    TEST_ENV="TRAVIS=true COV=${TEST_COVERAGE} LOG_LEVEL=${TEST_LOG_LEVEL} TEST=test/lib/heuristics/scheduling_*"
    ;;
  'split_clustering')
    TEST_ENV="TRAVIS=true COV=${TEST_COVERAGE} LOG_LEVEL=${TEST_LOG_LEVEL} INTENSIVE_TEST=true TEST=test/lib/interpreters/split_clustering_test.rb"
    ;;
  *)
    ;;
esac

APP_ENV=test bundle exec rake test ${TEST_ENV}
