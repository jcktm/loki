# Service node registration and staking contribution

Addresses is this guide are abbreviated. So the address L7q6DxQGnP6PQFe5bkV6DaGbgUj7TK7PG5dKv45mzTM6jQmoDbmZu7gfgVfnqp9yoSCtCd8GQEFLD7TKZu8UGL8335UuJ4Z would appear as thus:

    L7q6DxQGnP6P...

## Overview

Service node staking and registration is generally done in two parts:

1. First the service node operator registers the service node and provides
   their own contribution.
2. After the registration is in a block, the other contributors may make their
   contributions on the blockchain.

Each contributor must send at least 25% of the total staking requirement,
unless there is less than 25% remaining to be filled.

The service node operator should specify any addresses that are supposed to
participate in this service node in order to reserve their place.

## Basic syntax

The service node operator runs the following command from the service node:

    ./lokid --prepare-registration <address> <fraction> <address2> <fraction2> ... <contribution address> <contribution amount>

The address/fraction pairs are to reserve a portion of the service node reward for address1, address2, ..., etc. where fraction is between 0.25 and 1.

The contribution address and amount means that you will send `<contribution amount>` funds in a locked transfer for 30 days worth of blocks to `<contribution address>`

### Basic Example

To do a basic registration of a single contributor (you), you would run this:

    ./lokid --prepare-registration L7q6DxQGnP6P... 1 L7q6DxQGnP6P... 35000.0

This means the given address will receive 100% of the rewards, and the wallet will send 35000.0 to that address in a locked transfer.

This will generate a signed command that is valid for two weeks to run in the CLI wallet.

### Shared Example

To do a basic registration with two participants, you would run this:

    ./lokid --prepare-registration L7q6DxQGnP6P...  0.5 L514yZNZuTHb... 0.5 L7q6DxQGnP6P... 17500.0

In this example, each of the two specified addresses will have 50% of the staking contribution reserved for them. The first address is specified for the locked transaction of 17500.0 at the end.

This will generate a signed command that is valid for two weeks to run in the CLI wallet.

After this transaction is in the blockchain, the second contributor may contribute their portion of the service node staking amount from the CLI like this:

    stake <pubkey> L514yZNZuTHb... 17500.0

Where `<pubkey>` is the service node public key and the address specified is their own address, as it appears in the registration.

### Pooled example

To do a basic registration with one guaranteed participant of 25%, and an open number of pooled participants, you would run this:

    ./lokid --prepare-registration L7q6DxQGnP6P... 0.25 L7q6DxQGnP6P... 8750.0

This means reserve 25% for the specified address, then send a 30-day locked transfer of 8750.0 to the specified address.

Then participants who want to contribute to this pool can do so with this command in the CLI:

    stake <pubkey> L514yZNZuTHb... <amount>

Where `<pubkey>` is the public key for the service node and `<amount>` is the amount they want to contribute.
