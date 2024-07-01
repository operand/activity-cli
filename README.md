# Activity CLI

This CLI allows invoking various system activities for the purpose of generating
and validating telemetry data. The following actions are supported:

- Process creation
- File creation, modification, and deletion
- Network activity

Each action taken is saved in JSON format within `activity_log.jsonl`.

## Implementation

The CLI was created using the [Thor gem](https://github.com/rails/thor).

I chose JSONL as the format because I felt that was appropriate. Each line is a
complete JSON object containing the command used and its details.

I created a [docker-compose.yml](./docker-compose.yml) file for testing this on
linux. See the usage section below for how to use it.

Tests were written using Minitest in [cli_test.rb](./cli_test.rb). I was a bit
loose on some of the assertions but given more time I would make the assertions
more strict.


# Installation

Install Ruby >= 3.2 on the target system. Then run the following command to
install necessary libraries.

```sh
bundle install
```

# Usage

To run locally use:

```sh
bundle exec activity-cli
```

To run commands within a local linux container use:

```sh
docker compose run --rm -workdir /app app bundle exec activity-cli
```

# Testing

```sh
ruby cli_test.rb
```
