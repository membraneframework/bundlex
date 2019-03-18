defmodule Bundlex.CNode do
  @moduledoc """
  Utilities to ease interaction with Bundlex-based CNodes, so they can be treated
  more like Elixir processes / `GenServer`s.
  """

  use Bunch
  alias Bundlex.Helper.MixHelper

  @typedoc """
  Reference to the CNode.

  Consists of pid of CNode's supervisor and CNode name.
  """
  @type ref_t :: {pid, node}

  @type on_start_t :: {:ok, ref_t} | {:error, :spawn_cnode | :connect_to_cnode}

  @doc """
  Spawns and connects to CNode `cnode_name` from application of calling module.

  See `#{inspect(__MODULE__)}.start_link/2` for more details.
  """
  defmacro start_link(native_name) do
    app = MixHelper.get_app!(__CALLER__.module)

    quote do
      unquote(__MODULE__).start_link(unquote(app), unquote(native_name))
    end
  end

  @doc """
  Spawns and connects to CNode `cnode_name` from application of calling module.

  See `#{inspect(__MODULE__)}.start/2` for more details.
  """
  defmacro start(native_name) do
    app = MixHelper.get_app!(__CALLER__.module)

    quote do
      unquote(__MODULE__).start(unquote(app), unquote(native_name))
    end
  end

  @doc """
  Spawns and connects to CNode `cnode_name` from application `app`.

  The CNode is passed the following command line arguments:
  - host name,
  - alive name,
  - node name,
  - cookie,
  - creation number.

  After CNode startup, these parameters should be passed to
  [`ei_connect_xinit`](http://erlang.org/doc/man/ei_connect.html#ei_connect_xinit)
  function, and CNode should be published and await connection. Once the CNode is
  published, it should print a line starting with `ready` to the standard output.

  Under the hood, this function starts a supervisor, which is responsible for
  monitoring the CNode and monitoring calling process to be able to do proper
  cleanup upon a crash. On startup, the supervisor does the following:
  1. Makes current node distributed if it is not done yet (see `Node.start/3`).
  1. Assigns CNode a unique name.
  1. Starts CNode OS process using `Port.open/2`.
  1. Waits (at most 5 seconds) until a line starting with `ready` is printed out
  (this line is captured and not forwarded to the stdout).
  1. Connects to the CNode.
  """
  @spec start_link(app :: atom, native_name :: atom) :: on_start_t
  def start_link(app, native_name) do
    do_start(app, native_name, true)
  end

  @doc """
  Works the same way as `start_link/2`, but does not link to CNode's supervisor.
  """
  @spec start(app :: atom, native_name :: atom) :: on_start_t
  def start(app, native_name) do
    do_start(app, native_name, false)
  end

  defp do_start(app, native_name, link?) do
    {:ok, pid} =
      GenServer.start(
        __MODULE__.Supervisor,
        %{app: app, native_name: native_name, caller: self(), link?: link?}
      )

    receive do
      {^pid, res} -> res
    end
  end

  @doc """
  Disconnects from CNode.

  It is the responsibility of the CNode to exit upon connection loss.
  """
  @spec stop(ref_t) :: :ok | {:error, :disconnect_cnode}
  def stop({pid, _cnode}) do
    GenServer.call(pid, :stop)
  end

  @doc """
  Starts monitoring CNode from the calling process.
  """
  @spec monitor(ref_t) :: reference
  def monitor({pid, _cnode}) do
    Process.monitor(pid)
  end

  @doc """
  Makes a synchronous call to CNode and waits for its reply.

  The CNode is supposed to send back a `{cnode, response}` tuple where `cnode`
  is the node name of CNode. If the response doesn't come in within `timeout`,
  error is raised.

  Messages are exchanged directly (without interacting with CNode's supervisor).
  """
  @spec call(ref_t, message :: term, timeout :: non_neg_integer | :infinity) :: response :: term
  def call({_pid, cnode}, message, timeout \\ 5000) do
    Kernel.send({:any, cnode}, message)

    receive do
      {^cnode, response} -> response
    after
      timeout -> raise "Timeout upon call to the CNode #{inspect(cnode)}"
    end
  end

  @doc """
  Sends a message to cnode.

  The message is exchanged directly (without interacting with CNode's supervisor).
  """
  @spec send(ref_t, message :: term) :: :ok
  def send({_pid, cnode}, message) do
    Kernel.send({:any, cnode}, message)
    :ok
  end
end
