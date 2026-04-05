  

#  Under Construction! 

**Uh-oh — the page you are looking for didn’t survive the latest round of funding cuts.** Try using the [****](#) **search button** at the top of the page or searching on [Google](https://www.google.com/search?q=site%3Aar-puuk.github.io).

**While we wait for the public comment period, why not test your Transportation & Data Science smarts?** It’s more fun than hitting the [back](javascript:history.back()) button. Probably.

  
  
  

------------------------------------------------------------------------

> **TIP:**
>
> Complete these interactive R exercises to test your skills in transportation planning and data analysis. Each exercise builds on real-world scenarios you’ll encounter as a transportation professional.

------------------------------------------------------------------------

## 🧠 **Knowledge Test**

*Test your understanding of transportation planning fundamentals*

### Question 1: Traffic Signal Timing ⏱️

If a traffic light has a 90-second cycle and the green light lasts 60 seconds, how many cars can pass through if each car takes 3 seconds to clear the intersection?

`# Calculate how many cars can pass in one green phase green_time <- 60 # seconds time_per_car <- 3 # seconds # Divide green time by time per car cars_per_cycle <- green_time / time_per_car cars_per_cycle`

``` r
# Calculate how many cars can pass in one green phase
green_time <- 60  # seconds
time_per_car <- 3  # seconds

# Divide green time by time per car
cars_per_cycle <- green_time / time_per_car

cars_per_cycle
```

### Question 2: Level of Service 🚦

Calculate the volume-to-capacity (V/C) ratio for an intersection with 1,600 vehicles/hour and capacity of 1,800 vehicles/hour. What LOS category does this represent? (A-C: ≤0.8, D: 0.8-0.9, E-F: \>0.9)

`volume <- 1600 capacity <- 1800 # Calculate V/C ratio vc_ratio <- volume / capacity # Determine LOS category based on thresholds los_category <- if (vc_ratio <= 0.8) { "A-C" } else if (vc_ratio <= 0.9) { "D" } else { "E-F" } list(vc_ratio = vc_ratio, los_category = los_category)`

``` r
volume <- 1600
capacity <- 1800

# Calculate V/C ratio
vc_ratio <- volume / capacity

# Determine LOS category based on thresholds
los_category <- if (vc_ratio <= 0.8) {
  "A-C"
} else if (vc_ratio <= 0.9) {
  "D" 
} else {
  "E-F"
}

list(vc_ratio = vc_ratio, los_category = los_category)
```

### Question 3: Modal Split 🚌🚲🚗

In a city where 40% of trips are by car, 25% by transit, 20% by walking, and 15% by cycling, what percentage of non-car trips are made by transit?

`car_percent <- 40 transit_percent <- 25 walking_percent <- 20 cycling_percent <- 15 # Calculate percentage of non-car trips that are transit non_car_total <- 100 - car_percent # 60% transit_share_of_non_car <- (transit_percent / non_car_total) * 100 transit_share_of_non_car`

``` r
car_percent <- 40
transit_percent <- 25
walking_percent <- 20
cycling_percent <- 15

# Calculate percentage of non-car trips that are transit
non_car_total <- 100 - car_percent  # 60%
transit_share_of_non_car <- (transit_percent / non_car_total) * 100

transit_share_of_non_car
```

### Question 4: Trip Generation 🏠

A residential development has 200 housing units. Using ITE trip generation rate of 9.5 trips per dwelling unit per day, calculate total daily trips. If 15% occur during PM peak hour, how many PM peak trips?

`housing_units <- 200 trip_rate <- 9.5 pm_peak_percent <- 15 # Calculate total daily trips total_daily_trips <- housing_units * trip_rate # Calculate PM peak hour trips pm_peak_trips <- total_daily_trips * (pm_peak_percent / 100) list(daily = total_daily_trips, pm_peak = pm_peak_trips)`

``` r
housing_units <- 200
trip_rate <- 9.5
pm_peak_percent <- 15

# Calculate total daily trips
total_daily_trips <- housing_units * trip_rate

# Calculate PM peak hour trips
pm_peak_trips <- total_daily_trips * (pm_peak_percent / 100)

list(daily = total_daily_trips, pm_peak = pm_peak_trips)
```

### Question 5: Transit Frequency 🚍

A bus route operates every 12 minutes during peak hours. How many buses pass a given stop in one hour? If each bus has 40-passenger capacity and average load is 75%, what’s the hourly passenger capacity past that stop?

`frequency_minutes <- 12 bus_capacity <- 40 load_factor <- 0.75 # Calculate buses per hour buses_per_hour <- 60 / frequency_minutes # Calculate hourly passenger capacity hourly_passenger_capacity <- buses_per_hour * bus_capacity * load_factor list(buses_per_hour = buses_per_hour, hourly_capacity = hourly_passenger_capacity)`

``` r
frequency_minutes <- 12
bus_capacity <- 40
load_factor <- 0.75

# Calculate buses per hour
buses_per_hour <- 60 / frequency_minutes

# Calculate hourly passenger capacity
hourly_passenger_capacity <- buses_per_hour * bus_capacity * load_factor

list(buses_per_hour = buses_per_hour, hourly_capacity = hourly_passenger_capacity)
```

------------------------------------------------------------------------

## 🚀 **Skills Test**

*Put your R and dplyr skills to work with real transportation datasets*

### Question 1: High-Traffic Location Analysis 📊

Using the `traffic_data` dataset, filter for locations with AADT \> 15,000 and count how many locations meet this criteria.

`# Filter for high-traffic locations and count them high_traffic <- traffic_data |> filter(aadt > 15000) # Count the results count_high_traffic <- nrow(high_traffic) count_high_traffic`

``` r
# Filter for high-traffic locations and count them
high_traffic <- traffic_data |>
  filter(aadt > 15000)

# Count the results
count_high_traffic <- nrow(high_traffic)

count_high_traffic
```

### Question 2: Safety Rate Calculation 🔍

Calculate the accident rate per 1,000 AADT for each location. Create a new column called `accident_rate` and arrange by highest rate.

`# Calculate accident rates and arrange safety_analysis <- traffic_data |> mutate(accident_rate = (accidents_2023 / aadt) * 1000) |> arrange(desc(accident_rate)) # Show the results safety_analysis`

``` r
# Calculate accident rates and arrange
safety_analysis <- traffic_data |>
  mutate(accident_rate = (accidents_2023 / aadt) * 1000) |>
  arrange(desc(accident_rate))

# Show the results
safety_analysis
```

### Question 3: Transit Efficiency Analysis 🚌

Calculate riders per mile for each transit route and identify the most efficient route (highest riders per mile).

`# Calculate efficiency and find the best route transit_efficiency <- transit_data |> mutate(riders_per_mile = daily_riders / route_length_miles) |> arrange(desc(riders_per_mile)) # Get the most efficient route name most_efficient <- transit_efficiency |> slice(1) |> pull(route) most_efficient`

``` r
# Calculate efficiency and find the best route
transit_efficiency <- transit_data |>
  mutate(riders_per_mile = daily_riders / route_length_miles) |>
  arrange(desc(riders_per_mile))

# Get the most efficient route name
most_efficient <- transit_efficiency |>
  slice(1) |>
  pull(route)

most_efficient
```

### Question 4: Bike Share Visualization 📈

Create a scatter plot showing the relationship between distance from downtown and daily trips for bike share stations. Add a smooth trend line.

`# Create the bike share analysis plot bike_plot <- ggplot(bike_data, aes(x = distance_downtown_km, y = daily_trips)) + geom_point(size = 3, alpha = 0.7, color = "steelblue") + geom_smooth(method = "lm", se = FALSE, color = "red") + labs( title = "Bike Share Usage vs Distance from Downtown", x = "Distance from Downtown (km)", y = "Daily Trips" ) + theme_minimal() bike_plot`

``` r
# Create the bike share analysis plot
bike_plot <- ggplot(bike_data, aes(x = distance_downtown_km, y = daily_trips)) +
  geom_point(size = 3, alpha = 0.7, color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  labs(
    title = "Bike Share Usage vs Distance from Downtown",
    x = "Distance from Downtown (km)",
    y = "Daily Trips"
  ) +
  theme_minimal()

bike_plot
```

### Question 5: Comprehensive Performance Summary 🏆

Create a summary table showing for each location: total daily volume, accidents per 1000 vehicles, and congestion level (Low: \<3hrs, Medium: 3-5hrs, High: \>5hrs).

`# Create comprehensive performance summary performance_summary <- traffic_data |> mutate( daily_volume = aadt, accidents_per_1000 = (accidents_2023 / aadt) * 1000, congestion_level = case_when( congestion_hours < 3 ~ "Low", congestion_hours <= 5 ~ "Medium", TRUE ~ "High" ) ) |> select(location, daily_volume, accidents_per_1000, congestion_level) performance_summary`

``` r
# Create comprehensive performance summary
performance_summary <- traffic_data |>
  mutate(
    daily_volume = aadt,
    accidents_per_1000 = (accidents_2023 / aadt) * 1000,
    congestion_level = case_when(
      congestion_hours < 3 ~ "Low",
      congestion_hours <= 5 ~ "Medium", 
      TRUE ~ "High"
    )
  ) |>
  select(location, daily_volume, accidents_per_1000, congestion_level)

performance_summary
```

------------------------------------------------------------------------

## 🎯 Quiz Complete!

**Congratulations, You are now a Transportation Data Scientist!** 🏆

*P.S. - If you got this far, you’re definitely not lost anymore. You’re a certified Transportation Data Scientist! 🎯*

------------------------------------------------------------------------

*Built with [Quarto Live](https://r-wasm.github.io/quarto-live/) and [WebR](https://docs.r-wasm.org/webr/latest/)*
