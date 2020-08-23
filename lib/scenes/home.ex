defmodule ScenicNinja.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives

  @text_size 24
  @width 1000
  @height 600
  @blue 150
  @image_path :code.priv_dir(:scenic_ninja) |> Path.join("/static/images/castle3.png")
  @image_hash Scenic.Cache.Support.Hash.file!(@image_path, :sha)
  @graph Graph.build(font: :roboto, font_size: @text_size)
         |> add_specs_to_graph([
           rect_spec({@width, @height}, fill: {175, 216, @blue}, id: :background_color),
           rect_spec({@width, @height}, fill: {:image, @image_hash}, id: :background_image),
           rect_spec({@width, 20}, fill: {:color, :blue}, t: {0, @height - 20}, id: :floor)
         ])

  @frame_ms 64

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    # load the asset into the cache (run time)
    Scenic.Cache.Static.Texture.load(@image_path, @image_hash)

    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(viewport)

    # start animating
    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    state = %{
      width: width,
      height: height,
      graph: @graph,
      score: 0,
      frame_count: 0,
      frame_time: timer,
      blue_forward: true,
      blue: @blue
    }

    {:ok, state, push: @graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}}")
    {:noreply, state}
  end

  def handle_info(:frame, state) do
    state =
      state
      |> render_next_frame()

    {:noreply, state, push: state.graph}
  end

  def render_next_frame(%{width: width, height: height, frame_count: frame_count} = state) do
    {blue, blue_forward} = fade_background_colour(state)
    state.graph |> IO.inspect(label: "graph")

    graph =
      state.graph
      |> Graph.modify(:background_color, &rect(&1, {width, height}, fill: {175, 216, blue}))

    %{state | blue: blue, blue_forward: blue_forward, graph: graph, frame_count: frame_count + 1}
  end

  def fade_background_colour(%{blue: blue, blue_forward: false}) when blue <= 130,
    do: {blue, true}

  def fade_background_colour(%{blue: blue, blue_forward: true}) when blue < 255,
    do: {blue + 1, true}

  def fade_background_colour(%{blue: blue, blue_forward: false}) when blue > 130,
    do: {blue - 1, false}

  def fade_background_colour(%{blue: blue}), do: {blue, false}
end
