#!/bin/bash

# This is intended to be run the plugin's root directory. `.ci/docker-setup.sh`
# Ensure you have Docker installed locally and set the OPENSEARCH_VERSION environment variable.
set -e

VERSION_URL="https://raw.githubusercontent.com/elastic/logstash/master/ci/logstash_releases.json"

if [ "$OPENSEARCH_VERSION" ]; then
    echo "Fetching versions from $VERSION_URL"
    VERSIONS=$(curl --silent $VERSION_URL)
    if [[ "$SNAPSHOT" = "true" ]]; then
      OPENSEARCH_RETRIEVED_VERSION=$(echo $VERSIONS | jq '.snapshots."'"$OPENSEARCH_VERSION"'"')
      echo $OPENSEARCH_RETRIEVED_VERSION
    else
      OPENSEARCH_RETRIEVED_VERSION=$(echo $VERSIONS | jq '.releases."'"$OPENSEARCH_VERSION"'"')
    fi
    if [[ "$OPENSEARCH_RETRIEVED_VERSION" != "null" ]]; then
      # remove starting and trailing double quotes
      OPENSEARCH_RETRIEVED_VERSION="${OPENSEARCH_RETRIEVED_VERSION%\"}"
      OPENSEARCH_RETRIEVED_VERSION="${OPENSEARCH_RETRIEVED_VERSION#\"}"
      echo "Translated $OPENSEARCH_VERSION to ${OPENSEARCH_RETRIEVED_VERSION}"
      export OPENSEARCH_VERSION=$OPENSEARCH_RETRIEVED_VERSION
    fi

    echo "Testing against version: $OPENSEARCH_VERSION"

    if [[ "$OPENSEARCH_VERSION" = *"-SNAPSHOT" ]]; then
        cd /tmp

        jq=".build.projects.\"logstash\".packages.\"logstash-$OPENSEARCH_VERSION-docker-image.tar.gz\".url"
        result=$(curl --silent https://artifacts-api.elastic.co/v1/versions/$OPENSEARCH_VERSION/builds/latest | jq -r $jq)
        echo $result
        curl $result > logstash-docker-image.tar.gz
        tar xfvz logstash-docker-image.tar.gz  repositories
        echo "Loading docker image: "
        cat repositories
        docker load < logstash-docker-image.tar.gz
        rm logstash-docker-image.tar.gz
        cd -

        if [ "$INTEGRATION" == "true" ]; then

          cd /tmp

          jq=".build.projects.\"opensearch\".packages.\"opensearch-$OPENSEARCH_VERSION-docker-image.tar.gz\".url"
          result=$(curl --silent https://artifacts-api.elastic.co/v1/versions/$OPENSEARCH_VERSION/builds/latest | jq -r $jq)
          echo $result
          curl $result > opensearch-docker-image.tar.gz
          tar xfvz opensearch-docker-image.tar.gz  repositories
          echo "Loading docker image: "
          cat repositories
          docker load < opensearch-docker-image.tar.gz
          rm opensearch-docker-image.tar.gz
          cd -

        fi
    fi

    if [ -f Gemfile.lock ]; then
        rm Gemfile.lock
    fi

    cd .ci

    if [ "$INTEGRATION" == "true" ]; then
        docker-compose down
        docker-compose build
    else
        docker-compose down
        docker-compose build logstash
    fi
else
    echo "Please set the OPENSEARCH_VERSION environment variable"
    echo "For example: export OPENSEARCH_VERSION=6.2.4"
    exit 1
fi

