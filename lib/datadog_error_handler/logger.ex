defmodule DatadogErrorHandler.Logger do
  @moduledoc """
  Provides logging backend for Datadog.

  Funnels exceptions and error-level logging into Datadog error events.
  """
  import DatadogErrorHandler.ExceptionFormatter, only: [format_error: 2]

  alias DatadogErrorHandler.State

  @behaviour :gen_event

  @impl true
  def init(_opts) do
    with config <- Application.get_env(:logger, :datadog_error_handler),
         state <- State.new(config),
         {:ok, pid} <- get_or_start_statsd_pid(state),
         {:ok, state} <- State.apply_changes(state, statsd_pid: pid) do
      {:ok, state}
    else
      {:error, _reason} -> {:error, :no_start}
    end
  end

  @impl true
  def handle_call({:configure, changeset}, state) do
    {:ok, state} = State.apply_changes(state, changeset)

    {:ok, state, state}
  end

  @impl true
  def handle_call(_message, state),
    do: {:ok, :ok, state}

  @impl true
  def handle_event({_level, gleader, _event}, state) when node(gleader) != node(),
    do: {:ok, state}

  @impl true
  def handle_event(
        {level, _, {Logger, msg, _ts, meta}},
        %State{statsd_pid: pid, event_opts: opts, level: configured_level} = state
      ) do
    if Logger.compare_levels(level, configured_level) != :lt do
      with %{title: title, body: body, key: key} <- format_error(msg, meta) do
        opts = Map.put_new(opts, :aggregation_key, key)

        DogStatsd.event(pid, title, body, opts)
      end
    end

    {:ok, state}
  end

  @impl true
  def handle_event(
        {level, _, {DatadogErrorHandler.Plug, _msg, _ts, %{title: title, body: body, key: key}}},
        %State{statsd_pid: pid, event_opts: opts, level: configured_level} = state
      ) do
    if Logger.compare_levels(level, configured_level) != :lt do
      opts = Map.put_new(opts, :aggregation_key, key)

      DogStatsd.event(pid, title, body, opts)
    end

    {:ok, state}
  end

  @impl true
  def handle_event(_log, state), do: {:ok, state}

  @impl true
  def handle_info(_info, state), do: {:ok, state}

  defp get_or_start_statsd_pid(%State{statsd_pid: pid}) when is_pid(pid),
    do: {:ok, pid}

  defp get_or_start_statsd_pid(%State{statsd_host: host, statsd_port: port}) when is_port(port),
    do: DogStatsd.new(host, port)
end
