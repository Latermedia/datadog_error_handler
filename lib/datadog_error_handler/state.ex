defmodule DatadogErrorHandler.State do
  @moduledoc """
  Data structure for the state of the event handler loop.
  """

  @enforce_keys ~w(statsd_pid
                   statsd_host
                   statsd_port
                   event_opts)a

  defstruct [:statsd_pid, :statsd_host, :statsd_port, :event_opts, level: :error]

  @typedoc """
  Represents the state of the event handler.
  """
  @type t() :: %__MODULE__{
          statsd_pid: pid(),
          statsd_host: binary(),
          statsd_port: port(),
          event_opts: Keyword.t()
        }

  @doc """
  Creates a new state from the given configuration.
  """
  @spec new(Keyword.t()) ::
          {:ok, t()}
          | {:error, binary()}
  def new(props) do
    %__MODULE__{
      statsd_pid: props[:pid],
      statsd_host: props[:host],
      statsd_port: props[:port],
      event_opts: props[:event_opts]
    }
  end

  @doc """
  Applies given changes to the state.
  """
  @spec apply_changes(t(), Keyword.t()) ::
          t()
  def apply_changes(state = %__MODULE__{}, changeset \\ []) do
    changeset =
      changeset
      |> Enum.into(%{})
      |> Map.take(@enforce_keys)

    new_state =
      state
      |> Map.merge(changeset)
      |> update_in([:event_opts], fn opts -> Enum.into(opts || %{}, %{}) end)
      |> update_in([:event_opts], fn opts -> Map.put_new(opts, :alert_type, "error") end)
      |> update_in([:event_opts, :tags], fn
        nil ->
          []

        tags ->
          Enum.map(tags, fn
            {k, v} -> "#{k}:#{v}"
            tag -> tag
          end)
      end)

    if is_nil(new_state.statsd_host) and is_nil(new_state.statsd_port) and
         is_nil(new_state.statsd_pid) do
      {:error, "logger should be configured with statsd host and port, or statsd pid"}
    else
      {:ok, new_state}
    end
  end
end
