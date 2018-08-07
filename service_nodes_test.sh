#!/bin/bash

N=4

launch() {
  local other
  local detach
  detach="--detach"
  if (( $1 == 0 ))
  then
    other=$((N-1))
  else
    other=$(($1-1))
  fi
  if [ "$2" = "nodetach" ]
  then
    detach=
  fi
  build/release/bin/lokid --testnet --no-igd --p2p-bind-port 4808$1 \
                                 --rpc-bind-port 1812$1 \
                                 --rpc-restricted-bind-port 1832$1 \
                                 --zmq-rpc-bind-port 1822$1 \
                                 --p2p-bind-ip 127.0.0.1 \
                                 --data-dir .service_nodes_test$1 \
                                 --add-exclusive-node 127.0.0.1:4808$other \
                                 $detach
}

create_wallet() {
  echo Creating wallet #$1
  build/release/bin/loki-wallet-cli --daemon-address 127.0.0.1:1812$1 --testnet --generate-new-wallet .service_nodes_test_wallet$1 --password '' --mnemonic-language English status > /dev/null
}

wallet_cmd() {
  local x=$1
  shift
  build/release/bin/loki-wallet-cli --daemon-address 127.0.0.1:1812$x --testnet --log-level 4 --log-file .service_nodes_test_wallet$x.log --wallet-file .service_nodes_test_wallet$x --password '' $@
}

daemon_cmd() {
  local x=$1
  shift
  build/release/bin/lokid --testnet --no-igd --rpc-bind-port 1812$x $@
}

launch_all() {
  for i in $(seq 0 $((N-1)))
  do
    launch $i
  done

  echo "everybody launched, waiting 3 seconds"

  sleep 3
}

create_all_wallets() {
  for i in $(seq 0 $((N-1)))
  do
    create_wallet $i
  done
}

exit_and_cleanup() {
  pkill -9 lokid

  sleep 1

  touch .service_nodes_test_delete
  rm -rf .service_nodes_test*
}

mine_n_blocks() {
  # start_height=$(daemon_cmd $1 print_height)
  local n=$2
  # echo "Mining $n blocks from $start_height"
  local x=1
  local y=1
  while (( x <= n ))
  do
    x=$((x*2))
    y=$((y+1))
  done
  x=$((x/2))
  y=$((y-1))
  echo Mining $n on wallet \#$1
  while (( x >= 1 ))
  do
    if (( n >= x ))
    then
      local start_height=$(daemon_cmd $1 print_height)
      local height=0
      wallet_cmd $1 start_mining $y > /dev/null
      while (( height < start_height+x ))
      do
        height=$(daemon_cmd $1 print_height)
        if (( x > 10 ))
        then
          sleep 3
        fi
      done
      wallet_cmd $1 stop_mining > /dev/null
      n=$((n-x))
    fi
    x=$((x/2))
    y=$((y-1))
  done
  # local end_height=$(daemon_cmd $1 print_height)
  # echo "Finished mining $2 blocks from $start_height, end height: $end_height"
}

all_mine_n_blocks() {
  for i in $(seq 0 $((N-1)))
  do
    mine_n_blocks $i $1
  done
}

refresh_all() {
  for i in $(seq 0 $((N-1)));do wallet_cmd $i refresh;done
}

get_address() {
  wallet_cmd $1 address | tail -1 | cut -d' ' -f3
}

get_balance() {
  wallet_cmd $1 refresh | grep balance | cut -d' ' -f2 | cut -d, -f1
}

get_unlocked_balance() {
  wallet_cmd $1 refresh | grep balance | cut -d' ' -f5
}

basic_registration() {
  echo Basic registration of 100 on wallet \#$1
  reg_args=($(daemon_cmd $1 --prepare-registration $(get_address $1) 1 100 | grep register))
  echo -e '\nY' | wallet_cmd $1 ${reg_args[@]}
}

setup() {
  exit_and_cleanup
  launch_all
  create_all_wallets
  all_mine_n_blocks 64
}

equal() {
  local x=$(($1-$2))
  (( x < 1e-10 && x > -1e-10))
}

basic_registration_test() {
  local passed=true

  local balance=$(get_balance 1)

  # refresh to enable per output unlock
  refresh_all > /dev/null

  basic_registration 1
  mine_n_blocks 0 1                               #not the first block

  # check that it is registered

  local new_balance=$(get_balance 1)
  local unlocked_balance=$(get_unlocked_balance 1)

  echo Checking used 3 rewards of 45

  if (( unlocked_balance != balance - 45 * 3 ))
  then
    echo "unlocked balance not subtracted 100"
    echo balance is $balance, new unlocked balance: $unlocked_balance
    return
  fi

  echo Checking balance is used 0.02 fee
  if (( new_balance != balance - 0.020000000 ))
  then
    echo "didn't stake everything $balance, new balance: $new_balance"
    return
  fi

  balance=$new_balance
  mine_n_blocks 0 10                              #ten blocks

  unlocked_balance=$(get_unlocked_balance 1)

  echo "Checking unlocked balance after 10 blocks is released the change"
  if (( unlocked_balance != balance - 100 ))
  then
    echo "Expeched there to be exactly 100 locked. unlocked balance is $unlocked_balance, balance is $balance"
    return
  fi

  local total_blocks=$((30*5 + 30 - 2 - 10))

  balance=$(get_balance 1)
  mine_n_blocks 0 $total_blocks                   #all but 12 blocks

  new_balance=$(get_balance 1)

  if (( 50 * total_blocks != new_balance - balance ))
  then
    echo "expected to receive $((50 * total_blocks)), actually received $((new_balance - balance))"
    return
  fi

  balance=$new_balance

  basic_registration 1 # this is to check that registration fails.
  mine_n_blocks 0 1                               #second block

  new_balance=$(get_balance 1)

  if ! equal $(( balance + 50 - 1 * 0.016 )) $new_balance
  then
    echo "Didn't get second last reward. Balance is $balance, new balance is $new_balance"
    return
  fi

  balance=$new_balance

  mine_n_blocks 0 1                               #last block

  new_balance=$(get_balance 1)

  if ! equal $(( balance + 50 )) $new_balance
  then
    echo "Didn't receive final reward. Balance is $balance, new balance is $new_balance"
    return
  fi

  balance=$new_balance
  mine_n_blocks 0 1                               #empty block

  new_balance=$(get_balance 1)

  if ! equal $balance $new_balance
  then
    echo "REceived something after expiration"
    echo balance is $balance
    echo new balance is $new_balance
    return
  fi

  balance=$new_balance

  # check that service node list is empty
  basic_registration 1
  mine_n_blocks 0 1                               #new registration

  new_balance=$(get_balance 1)

  if ! equal $((balance-0.02)) $new_balance
  then
    echo "Received balance when should not: balance is $balance new balance is $new_balance"
    return
  fi

  balance=$new_balance

  mine_n_blocks 0 1                               #one block in new registration

  new_balance=$(get_balance 1)

  if ! equal $((balance+50)) $new_balance
  then
    echo "DIdn't receive ifrst reward after expiriation"
    return
  fi

  echo "Passed all tests"
}

unlocked_balance_test() {
  mine_n_blocks 0 128
  wallet_cmd 0 refresh
  echo -e '\nY\nY' | wallet_cmd 0 locked_transfer $(get_address 1) 1 99999 >/dev/null
  mine_n_blocks 0 16
  echo "Thes eshould be the same: "
  local x=$(get_unlocked_balance 1)
  local y=$(get_unlocked_balance 1)
  if ! equal $x $y
  then
    echo "not equal! $x $y"
    return
  fi
  echo -e '\nY\nY' | wallet_cmd 0 transfer $(get_address 1) 10 > /dev/null
  mine_n_blocks 0 16
  echo refresh to see initial balance in wallet \#1: $(get_unlocked_balance 1)
  echo -e '\nY\nY' | wallet_cmd 1 locked_transfer $(get_address 1) 1 99999
  mine_n_blocks 0 16
  echo "Thes eshould be the same and "
  x=$(get_unlocked_balance 1)
  y=$(get_unlocked_balance 1)
  if ! equal $x $y
  then
    echo "not equal! $x $y"
    return
  fi
}

main() {
  setup
  basic_registration_test
  # unlocked_balance_test
  # exit_and_cleanup
}

# trap exit_and_cleanup EXIT

# main
