#!/bin/bash
set -ex

export PATH=$BUILD_DIR/gradle/bin:$PATH

wait_for_opensearch() {
  echo "Waiting for opensearch to respond..."
  opensearch_url="http://opensearch:9200"
  count=120
  while ! curl --silent $opensearch_url && [[ $count -ne 0 ]]; do
    count=$(( $count - 1 ))
    [[ $count -eq 0 ]] && return 1
    sleep 1
  done
  echo "OpenSearch is Up !"

  return 0
}

if [[ "$INTEGRATION" != "true" ]]; then
  bundle exec rspec -fd spec/filters -t ~integration
else
  extra_tag_args="--tag integration"
  wait_for_opensearch
  bundle exec rspec -fd $extra_tag_args --tag opensearch_version:$OPENSEARCH_VERSION spec/filters/integration
fi
