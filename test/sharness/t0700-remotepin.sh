#!/usr/bin/env bash

test_description="Test ipfs remote pinning operations"

. lib/test-lib.sh

test_remote_pins() {
  BASE=$1
  if [ -n "$BASE" ]; then
    BASE_ARGS="--cid-base=$BASE"
  fi

  test_expect_success "create some hashes using base $BASE" '
    HASH_A=$(echo "A" | ipfs add $BASE_ARGS -q --pin=false)
  '

  test_expect_success "check connection to pinning service" '
    ipfs pin remote ls --enc=json
  '

  test_expect_success "'ipfs pin remote add'" '
    ID_A=$(ipfs pin remote add --enc=json $BASE_ARGS --name=name_a $HASH_A | jq --raw-output .ID)
  '

  test_expect_success "'ipfs pin remote ls' for existing pins by name" '
    FOUND_ID_A=$(ipfs pin remote ls --enc=json --name=name_a --cid=$HASH_A | jq --raw-output .ID | grep $ID_A) &&
    echo $ID_A > expected &&
    echo $FOUND_ID_A > actual &&
    test_cmp expected actual
  '

  test_expect_success "'ipfs pin remote rm' an existing pin by ID" '
    ipfs pin remote rm --enc=json $ID_A
  '

  test_expect_success "'ipfs pin remote ls' for deleted pin" '
    ipfs pin remote ls --enc=json --name=name_a | jq --raw-output .ID > list
    test_expect_code 1 grep $ID_A list
  '
}

test_init_ipfs

if [ -z "$IPFS_REMOTE_PIN_SERVICE" ] || [ -z "$IPFS_REMOTE_PIN_KEY" ]; then
        # create user on pinning service
        test_expect_success "creating test user on remote pinning service" '
                echo CI host IP address ${CI_HOST_IP} &&
                IPFS_REMOTE_PIN_SERVICE=http://${CI_HOST_IP}:5000/api/v1 &&
                IPFS_REMOTE_PIN_KEY=$(curl -X POST $IPFS_REMOTE_PIN_SERVICE/users -d email=sharness@ipfs.io | jq --raw-output .access_token)
        '
fi

test_expect_success "verify the pin service is reachable" '
  curl $IPFS_REMOTE_PIN_SERVICE
'

test_remote_pins ""

# test_kill_ipfs_daemon

test_done
