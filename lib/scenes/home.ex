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
  @ground_color {:color, :blue}
  @platform_size {100, 10}
  @floor rect_spec({@width, 20}, fill: @ground_color, t: {0, @height - 20}, id: :floor)
  @platform1 rect_spec(@platform_size, fill: @ground_color, t: {450, 500})
  @platform2 rect_spec(@platform_size, fill: @ground_color, t: {300, 400})
  @platform3 rect_spec(@platform_size, fill: @ground_color, t: {600, 400})
  @platform4 rect_spec(@platform_size, fill: @ground_color, t: {200, 300})
  @platform5 rect_spec(@platform_size, fill: @ground_color, t: {700, 300})
  @platform6 rect_spec(@platform_size, fill: @ground_color, t: {100, 200})
  @platform7 rect_spec(@platform_size, fill: @ground_color, t: {800, 200})
  @platform8 rect_spec(@platform_size, fill: @ground_color, t: {0, 100})
  @platform9 rect_spec(@platform_size, fill: @ground_color, t: {900, 100})

  @left_moving_plat_x 200
  @right_moving_plat_x 700
  @left_moving_plat rect_spec(@platform_size,
                      fill: @ground_color,
                      t: {@left_moving_plat_x, 200},
                      id: :left_moving_plat
                    )
  @right_moving_plat rect_spec(@platform_size,
                       fill: @ground_color,
                       t: {@right_moving_plat_x, 200},
                       id: :right_moving_plat
                     )

  @platforms [
    @platform1,
    @platform2,
    @platform3,
    @platform4,
    @platform5,
    @platform6,
    @platform7,
    @platform8,
    @platform9,
    @left_moving_plat,
    @right_moving_plat
  ]
  @graph Graph.build(font: :roboto, font_size: @text_size)
         |> add_specs_to_graph([
           rect_spec({@width, @height}, fill: {175, 216, @blue}, id: :background_color),
           rect_spec({@width, @height},
             fill: {:image, @image_hash},
             id: :background_image
           ),
           @floor
         ])
         |> add_specs_to_graph(@platforms)

  @frame_ms 32

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
      blue: @blue,
      left_moving_plat_enabled: true,
      left_moving_plat_x: @left_moving_plat_x,
      right_moving_plat_enabled: false,
      right_moving_plat_x: @right_moving_plat_x
    }

    {:ok, state, push: @graph}
  end

  def handle_input(event, _context, state) do
    # Logger.info("Received event: #{inspect(event)}}")
    {:noreply, state}
  end

  def handle_info(:frame, state) do
    state =
      state
      |> render_next_frame()

    {:noreply, state, push: state.graph}
  end

  def render_next_frame(
        %{width: width, height: height, frame_count: frame_count} = state
      ) do
    # state.graph |> IO.inspect(label: "graph")
    {blue, blue_forward} = fade_background_colour(state)

    {left_moving_plat_x, left_moving_plat_enabled} = move_left_platform(state)

    {right_moving_plat_x, right_moving_plat_enabled} = move_right_platform(state)

    graph =
      state.graph
      |> Graph.modify(
        :background_color,
        &rect(&1, {width, height}, fill: {175, 216, blue})
      )
      |> Graph.modify(
        :left_moving_plat,
        &rect(&1, @platform_size,
          fill: @ground_color,
          t: {left_moving_plat_x, 200},
          id: :left_moving_plat
        )
      )
      |> Graph.modify(
        :right_moving_plat,
        &rect(&1, @platform_size,
          fill: @ground_color,
          t: {right_moving_plat_x, 200},
          id: :right_moving_plat
        )
      )

    %{
      state
      | blue: blue,
        blue_forward: blue_forward,
        graph: graph,
        frame_count: frame_count + 1,
        left_moving_plat_x: left_moving_plat_x,
        left_moving_plat_enabled: left_moving_plat_enabled,
        right_moving_plat_x: right_moving_plat_x,
        right_moving_plat_enabled: right_moving_plat_enabled
    }
  end

  def fade_background_colour(%{blue: blue, blue_forward: false}) when blue <= 130,
    do: {blue, true}

  def fade_background_colour(%{blue: blue, blue_forward: true}) when blue < 255,
    do: {blue + 1, true}

  def fade_background_colour(%{blue: blue, blue_forward: false}) when blue > 130,
    do: {blue - 1, false}

  def fade_background_colour(%{blue: blue}), do: {blue, false}

  def move_left_platform(%{left_moving_plat_enabled: true, left_moving_plat_x: left_x}) do
    new_x = left_x + 2
    {new_x, not (new_x == 400)}
  end

  def move_left_platform(%{left_moving_plat_enabled: false, left_moving_plat_x: left_x}) do
    new_x = left_x - 2
    {new_x, new_x == 200}
  end

  def move_right_platform(%{
        right_moving_plat_enabled: true,
        right_moving_plat_x: right_x
      }) do
    new_x = right_x + 2
    {new_x, not (new_x == 700)}
  end

  def move_right_platform(%{
        right_moving_plat_enabled: false,
        right_moving_plat_x: right_x
      }) do
    new_x = right_x - 2
    {new_x, new_x == 500}
  end
end
