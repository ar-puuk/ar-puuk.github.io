library(shiny) # <1>
library(mapgl) # <2>

ui <- shiny::fluidPage( # <3>
  tags$link(
    href = "https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap",
    rel="stylesheet"
  ),
  mapgl::story_map( # <4>
    map_id = "map",
    font_family = "Poppins",
    sections = list( # <5>
      "intro" = mapgl::story_section(
        title = "Introduction",
        content = "Hello I am Pukar Bhandari; and this is my life journey."
      ),
      "birth_place" = mapgl::story_section(
        title = "Birth Place",
        content = "This is where I was born."
      ),
      "lower_primary" = mapgl::story_section(
        title = "Kankai Education Foundation",
        content = "This is where I studied Nursery to Grade 3."
      ),
      "upper_primary" = mapgl::story_section(
        title = "Laligurans English School",
        content = "This is where I studied Grade 4 & Grade 5."
      ),
      "middle_school" = mapgl::story_section(
        title = "Birat Jyoti English Secondary School",
        content = "This is where I studied Grade 6 & Grade 7."
      ),
      "secondary_school" = mapgl::story_section(
        title = "Little Flowers' English School",
        content = "This is where I studied Grade 8 to Grade 10."
      ),
      "higher_secondary" = mapgl::story_section(
        title = "Kanchanjunga English Higher Secondary School",
        content = "This is where I studied Higher Secondary (Plus 2)."
      ),
      "bachelors" = mapgl::story_section(
        title = "Institute of Engineering Pulchowk Campus",
        content = "This is where I obtained my Bachelor's Degree in Architecture."
      ),
      "masters" = mapgl::story_section(
        title = "University of Utah",
        content = "This is where I obtained my Master of City & Metropolitan Planning degree."
      ),
      "work_1" = mapgl::story_section(
        title = "Metro Analytics",
        content = "This is where I lived and worked between 2023-2025."
      ),
      "work_2" = mapgl::story_section(
        title = "Wasatch Front Regional Council",
        content = "This is where I live and work currently."
      )
    ),
    map_type = "maplibre"
  )
)

server <- function(input, output, session) { # <6>
  output$map <- mapgl::renderMaplibre({ # <7>
    mapgl::maplibre(
      style = "https://tiles.openfreemap.org/styles/liberty", # <8>
      center = c(0, 0),
      zoom = 2.75,
      scrollZoom = FALSE
    ) |>
      mapgl::set_projection(projection = "globe") |> # <9>
      mapgl::add_globe_control() |>
      mapgl::add_navigation_control(visualize_pitch = TRUE) |>
      mapgl::add_globe_minimap(position = "bottom-left")
  })

  mapgl::on_section("map", "intro", { # <10>
    mapgl::maplibre_proxy("map") |>
      mapgl::clear_markers() |>
      mapgl::fly_to(
        center = c(0, 0),
        zoom = 2.75,
        pitch = 0,
        bearing = 0
      )
  })

  mapgl::on_section("map", "birth_place", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(87.99371750247397, 26.646533355308083),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "lower_primary", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(87.99734666704784, 26.646179601882675),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "upper_primary", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(88.01116125198942, 26.608294715049524),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "middle_school", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(87.99218594227516, 26.620735015314324),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "secondary_school", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(87.99006631463702, 26.63185913816036),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "higher_secondary", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(87.99921328178023, 26.633744364809765),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "bachelors", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(85.31840215760691, 27.681136558618093),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "masters", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(-111.84448004883544, 40.76106105996334),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "work_1", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(-84.3938999520061, 33.76728402587881),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "work_2", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(-111.90422445885304, 40.76973849954712),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })
}

shiny::shinyApp(ui, server) # <11>
