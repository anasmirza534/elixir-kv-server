# KV

A distributed key-value store built with Elixir, featuring TCP server interface and pub/sub capabilities for distributed nodes.

## Manual testing for distributed nodes

shell 1

```sh
NODES="foo@anas-mac-mini,bar@anas-mac-mini" PORT=4040 iex --sname foo -S mix
```

shell 2

```sh
NODES="foo@anas-mac-mini,bar@anas-mac-mini" PORT=4041 iex --sname bar -S mix
```

in shell 1

```ex
:erpc.call(:"bar@anas-mac-mini", KV, :create_bucket, ["shopping"])

KV.lookup_bucket("shopping")
```

shell 3

```sh
telnet 127.0.0.1 4040

GET shopping milk

PUT shopping milk 10

```

shell 4

```sh
telnet 127.0.0.1 4041
GET shopping milk

SUBSCRIBE shopping
```

now in shell 3 (in telnet shell)

```sh
PUT shopping egg 12
```

now you will see in shell 4, new message coming in

```sh
output: egg SET TO 12
```
