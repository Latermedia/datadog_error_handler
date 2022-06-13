# Logger backend for Datadog

A fork of [aspett/dog-exceptex](https://github.com/aspett/dog-exceptex).

Funnels exceptions and error-level logging into error events via the Datadog Statsd agent.

## Requirements

- Elixir 1.13.4+
- Erlang 25.0.1 (OTP 25)

## Installation

The package can be installed by adding `datadog_error_handler` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:datadog_error_handler, "~> 0.1.0"}
  ]
end
```

To add the error handler as a `Logger` backend, put the following line in your `config/config.exs` file.

```elixir
config :logger, :backends, 
  [:console, DatadogErrorHandler.Logger]
```

You can configure the logger with the following configuration.

```elixir
# Configures Datadog error handler
config :logger, :datadog_error_handler,
  host: "statsd_host",
  port: port,
  event_opts: [
    priority: "normal",
    tags: [ 
      # arbitrary string values for the event tags
      environment: System.get_env("MIX_ENV"),
      app: "some-app",
    ]
  ]
```

If you wish to start a `Dogstatsd` process yourself, you may configure with `pid` configuration variable.
`Logger.configure_backend/2` is also supported.

## Phoenix / Plug support

To support logging Phoenix requests, add `use DatadogErrorHandler.Plug` below 
`use AppWeb, :router` in your router file.

## Running tests

```sh
$ mix deps.get
$ mix test
```

## Documentation

Documentation can be generated with `mix docs`.

## Licence

See LICENSE.