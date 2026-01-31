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
      "childhood" = mapgl::story_section(
        title = "Birtamode, Jhapa",
        content = "This is where I was born and spent the early part of my life until 2013."
      ),
      "bachelors" = mapgl::story_section(
        title = "Pulchowk, Lalitpur",
        content = "I then moved to Pulchowk in the pursuit of higher education. I obtained my Bachelor's Degree in Architecture from Institute of Engineering Pulchowk Campus in 2018."
      ),
      "masters" = mapgl::story_section(
        title = "Salt Lake City, UT",
        content = "In pursuit of even higher education, I moved to Salt Lake City, UT where I obtained my Master of City & Metropolitan Planning degree from the University of Utah in May 2023."
      ),
      "metro_analytics" = mapgl::story_section(
        title = "Atlanta, GA",
        content = "I then moved to Altanta in June 2023 to work as a transportation planner & analyst at Metro Analytics until September 2025."
      ),
      "wfrc_ut" = mapgl::story_section(
        title = "Back to Salt Lake City, UT",
        content = "After gaining entry-level experience in transportation planning, travel demand modeling, and data analytics, I moved back to Salt Lake City - a place I am personally and professionally attached to - in order to join the awesome Analytics team at the Wasatch Front Regional Council."
      )
    ),
    map_type = "maplibre"
  )
)

server <- function(input, output, session) { # <6>
  output$map <- mapgl::renderMaplibre({ # <7>
    mapgl::maplibre(
      style = mapgl::openfreemap_style("liberty"), # <8>
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

  mapgl::on_section("map", "childhood", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(87.99371750247397, 26.646533355308083),
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

  mapgl::on_section("map", "metro_analytics", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(-84.3938999520061, 33.76728402587881),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })

  mapgl::on_section("map", "wfrc_ut", {
    mapgl::maplibre_proxy("map") |>
      mapgl::fly_to(center = c(-111.90422445885304, 40.76973849954712),
                    zoom = 16,
                    pitch = 49,
                    bearing = 12.8)
  })
}

shiny::shinyApp(ui, server) # <11>
