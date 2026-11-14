\

#  Under Construction! 

**Uh-oh — the page you are looking for didn’t survive the latest round of funding cuts.** Try using the [****](#) **search button** at the top of the page or searching on [Google](https://www.google.com/search?q=site%3Aar-puuk.github.io).

**While we wait for the public comment period, why not test your Regional Planning & Data Science smarts?** It’s more fun than hitting the [back](javascript:history.back()) button. Probably.

\
\
\

------------------------------------------------------------------------

> **NOTE:**
>
> These interactive exercises use the kind of problems that come up in regional transportation planning: **safety screening, project prioritization, travel demand modeling and mapping**. Pick R or Python for each question, edit the code, and press **Run Code** and then **Submit Answer**; gradethis compares your code with the solution. All of the data is synthetic.

------------------------------------------------------------------------

## 🧠 **Knowledge Test**

*Five calculations every regional planner has done at least once*

### Question 1: Crash Rate per 100 Million VMT 🚧

A 3.2-mile corridor carries 24,000 vehicles per day (AADT). It had 48 crashes over 3 years. Vehicle miles traveled (VMT) over the study period is AADT × 365 days × years × length. What is the crash rate per 100 million VMT?

##  R

`aadt <- 24000 length_mi <- 3.2 years <- 3 crashes <- 48 # Vehicle miles traveled over the whole study period vmt <- aadt * 365 * years * length_mi # Crashes per 100 million VMT crash_rate <- crashes / vmt * 1e8 crash_rate`

``` r
aadt <- 24000
length_mi <- 3.2
years <- 3
crashes <- 48

# Vehicle miles traveled over the whole study period
vmt <- aadt * 365 * years * length_mi

# Crashes per 100 million VMT
crash_rate <- crashes / vmt * 1e8

crash_rate
```

##  Python

`aadt = 24000 length_mi = 3.2 years = 3 crashes = 48 # Vehicle miles traveled over the whole study period vmt = aadt * 365 * years * length_mi # Crashes per 100 million VMT crash_rate = crashes / vmt * 100_000_000 crash_rate`

``` python
aadt = 24000
length_mi = 3.2
years = 3
crashes = 48

# Vehicle miles traveled over the whole study period
vmt = aadt * 365 * years * length_mi

# Crashes per 100 million VMT
crash_rate = crashes / vmt * 100_000_000

crash_rate
```

### Question 2: Volume-Delay Function ⏱️

Assignment models slow links down as they fill up. The BPR function is `t = t0 * (1 + 0.15 * (v / c)^4)`. A link has a free-flow time of 12 minutes, a volume of 2,400 vehicles per hour and a capacity of 2,000. What is its congested travel time?

##  R

`t0 <- 12 # free-flow minutes volume <- 2400 capacity <- 2000 congested_time <- t0 * (1 + 0.15 * (volume / capacity)^4) congested_time`

``` r
t0 <- 12      # free-flow minutes
volume <- 2400
capacity <- 2000

congested_time <- t0 * (1 + 0.15 * (volume / capacity)^4)

congested_time
```

##  Python

`t0 = 12 # free-flow minutes volume = 2400 capacity = 2000 congested_time = t0 * (1 + 0.15 * (volume / capacity)**4) congested_time`

``` python
t0 = 12      # free-flow minutes
volume = 2400
capacity = 2000

congested_time = t0 * (1 + 0.15 * (volume / capacity)**4)

congested_time
```

### Question 3: Gravity Model Trip Distribution 🏙️

Zone A produces 1,000 trips. Zone B attracts 600 trips and is 2 minutes away; zone C attracts 400 trips and is 4 minutes away. With a friction factor of `travel_time^-2`, the trips from A to B are `P * (A_B * F_B) / (A_B * F_B + A_C * F_C)`. How many trips go from A to B?

##  R

`production_a <- 1000 attraction_b <- 600 attraction_c <- 400 friction_b <- 2^-2 # travel time of 2 minutes friction_c <- 4^-2 # travel time of 4 minutes trips_ab <- production_a * (attraction_b * friction_b) / (attraction_b * friction_b + attraction_c * friction_c) trips_ab`

``` r
production_a <- 1000
attraction_b <- 600
attraction_c <- 400

friction_b <- 2^-2   # travel time of 2 minutes
friction_c <- 4^-2   # travel time of 4 minutes

trips_ab <- production_a * (attraction_b * friction_b) / (attraction_b * friction_b + attraction_c * friction_c)

trips_ab
```

##  Python

`production_a = 1000 attraction_b = 600 attraction_c = 400 friction_b = 2**-2 # travel time of 2 minutes friction_c = 4**-2 # travel time of 4 minutes trips_ab = production_a * (attraction_b * friction_b) / (attraction_b * friction_b + attraction_c * friction_c) trips_ab`

``` python
production_a = 1000
attraction_b = 600
attraction_c = 400

friction_b = 2**-2   # travel time of 2 minutes
friction_c = 4**-2   # travel time of 4 minutes

trips_ab = production_a * (attraction_b * friction_b) / (attraction_b * friction_b + attraction_c * friction_c)

trips_ab
```

### Question 4: Mode Choice 🚌🚲🚗

A multinomial logit model gives each mode a utility. The probability of choosing a mode is `exp(U_mode) / sum(exp(U))`. With utilities of -1.2 for car, -1.8 for transit and -2.5 for bike, what share of travelers choose transit?

##  R

`utilities <- c(car = -1.2, transit = -1.8, bike = -2.5) p_transit <- exp(utilities["transit"]) / sum(exp(utilities)) p_transit`

``` r
utilities <- c(car = -1.2, transit = -1.8, bike = -2.5)

p_transit <- exp(utilities["transit"]) / sum(exp(utilities))

p_transit
```

##  Python

`utilities = {"car": -1.2, "transit": -1.8, "bike": -2.5} p_transit = np.exp(utilities["transit"]) / sum(np.exp(u) for u in utilities.values()) p_transit`

``` python
utilities = {"car": -1.2, "transit": -1.8, "bike": -2.5}

p_transit = np.exp(utilities["transit"]) / sum(np.exp(u) for u in utilities.values())

p_transit
```

### Question 5: Benefit-Cost Ratio 💰

A \$12 million project is expected to produce \$1.6 million in benefits each year for 20 years. With a 3% discount rate, the present value of an annual benefit stream is `annual * (1 - (1 + r)^-n) / r`. What is the benefit-cost ratio?

##  R

`cost <- 12 # $ million annual_benefit <- 1.6 # $ million per year years <- 20 rate <- 0.03 # Present value factor for a 20-year stream of equal annual benefits pv_factor <- (1 - (1 + rate)^-years) / rate bcr <- annual_benefit * pv_factor / cost bcr`

``` r
cost <- 12          # $ million
annual_benefit <- 1.6   # $ million per year
years <- 20
rate <- 0.03

# Present value factor for a 20-year stream of equal annual benefits
pv_factor <- (1 - (1 + rate)^-years) / rate

bcr <- annual_benefit * pv_factor / cost

bcr
```

##  Python

`cost = 12 # $ million annual_benefit = 1.6 # $ million per year years = 20 rate = 0.03 # Present value factor for a 20-year stream of equal annual benefits pv_factor = (1 - (1 + rate)**-years) / rate bcr = annual_benefit * pv_factor / cost bcr`

``` python
cost = 12            # $ million
annual_benefit = 1.6     # $ million per year
years = 20
rate = 0.03

# Present value factor for a 20-year stream of equal annual benefits
pv_factor = (1 - (1 + rate)**-years) / rate

bcr = annual_benefit * pv_factor / cost

bcr
```

------------------------------------------------------------------------

## 🚀 **Skills Test**

*Screen a corridor network, rank projects, build a trip table and map the results*

### Question 1: Safety Screening 🚧

The `segments` table has crash counts for eight corridors over 3 years. Add each segment’s crash rate per 100 million VMT and its share of crashes that were fatal or serious (KSI), rank the segments, and name the one with the highest rate.

##  R

`segments_ranked <- segments |> mutate( vmt_100m = aadt * 365 * 3 * length_mi / 1e8, crash_rate = crashes_3yr / vmt_100m, # crashes per 100 million VMT ksi_share = ksi_3yr / crashes_3yr # share of crashes that were fatal or serious ) |> arrange(desc(crash_rate)) top_segment <- segments_ranked$segment[1] # A look at the ranking (already written for you) ggplot(segments_ranked, aes(x = reorder(segment, crash_rate), y = crash_rate, fill = ksi_share)) + geom_col() + coord_flip() + scale_fill_viridis_c(option = "magma", direction = -1, name = "KSI share") + labs(x = NULL, y = "Crashes per 100M VMT", title = "Crash rate by segment") + theme_minimal()`

``` r
segments_ranked <- segments |>
  mutate(
    vmt_100m = aadt * 365 * 3 * length_mi / 1e8,
    crash_rate = crashes_3yr / vmt_100m,   # crashes per 100 million VMT
    ksi_share = ksi_3yr / crashes_3yr     # share of crashes that were fatal or serious
  ) |>
  arrange(desc(crash_rate))

top_segment <- segments_ranked$segment[1]

# A look at the ranking (already written for you)
ggplot(segments_ranked, aes(x = reorder(segment, crash_rate), y = crash_rate, fill = ksi_share)) +
  geom_col() +
  coord_flip() +
  scale_fill_viridis_c(option = "magma", direction = -1, name = "KSI share") +
  labs(x = NULL, y = "Crashes per 100M VMT", title = "Crash rate by segment") +
  theme_minimal()
```

##  Python

`segments_ranked = ( segments .assign(vmt_100m=segments["aadt"] * 365 * 3 * segments["length_mi"] / 1e8) .assign( crash_rate=lambda d: d["crashes_3yr"] / d["vmt_100m"], # crashes per 100 million VMT ksi_share=lambda d: d["ksi_3yr"] / d["crashes_3yr"], # share of crashes that were fatal or serious ) .sort_values("crash_rate", ascending=False) ) top_segment = segments_ranked["segment"].iloc[0] # A look at the ranking (already written for you) ranked = segments_ranked.sort_values("crash_rate") fig, ax = plt.subplots(figsize=(6, 4)) bars = ax.barh(ranked["segment"], ranked["crash_rate"], color="#d96e34") ax.set_xlabel("Crashes per 100M VMT") ax.set_title("Crash rate by segment") plt.tight_layout() plt.show()`

``` python
segments_ranked = (
    segments
    .assign(vmt_100m=segments["aadt"] * 365 * 3 * segments["length_mi"] / 1e8)
    .assign(
        crash_rate=lambda d: d["crashes_3yr"] / d["vmt_100m"],   # crashes per 100 million VMT
        ksi_share=lambda d: d["ksi_3yr"] / d["crashes_3yr"],    # share of crashes that were fatal or serious
    )
    .sort_values("crash_rate", ascending=False)
)

top_segment = segments_ranked["segment"].iloc[0]

# A look at the ranking (already written for you)
ranked = segments_ranked.sort_values("crash_rate")
fig, ax = plt.subplots(figsize=(6, 4))
bars = ax.barh(ranked["segment"], ranked["crash_rate"], color="#d96e34")
ax.set_xlabel("Crashes per 100M VMT")
ax.set_title("Crash rate by segment")
plt.tight_layout()
plt.show()
```

### Question 2: Project Prioritization 🏗️

Score each candidate project with weights of 40% safety, 35% mobility and 25% equity, rank them, and see how many of the top-ranked projects fit in a \$60 million program (take projects in rank order and stop when the running cost passes the budget).

##  R

`weights <- c(safety = 0.40, mobility = 0.35, equity = 0.25) budget <- 60 # $ million scored <- projects |> mutate(score = safety * weights["safety"] + mobility * weights["mobility"] + equity * weights["equity"]) |> arrange(desc(score)) |> mutate(cum_cost = cumsum(cost_m)) funded <- scored |> filter(cum_cost <= budget) n_funded <- nrow(funded) # Score against cost, funded projects highlighted (already written for you) ggplot(scored, aes(x = cost_m, y = score, color = cum_cost <= budget, label = project)) + geom_point(size = 4) + geom_text(hjust = "inward", vjust = -1, size = 3, show.legend = FALSE) + scale_color_manual(values = c("TRUE" = "#2e9b4e", "FALSE" = "#9aa0a6"), labels = c("TRUE" = "Funded", "FALSE" = "Not funded"), name = NULL) + scale_x_log10() + labs(x = "Cost ($ million, log scale)", y = "Weighted score", title = "Project scores and the $60M program") + theme_minimal()`

``` r
weights <- c(safety = 0.40, mobility = 0.35, equity = 0.25)
budget <- 60  # $ million

scored <- projects |>
  mutate(score = safety * weights["safety"] + mobility * weights["mobility"] + equity * weights["equity"]) |>
  arrange(desc(score)) |>
  mutate(cum_cost = cumsum(cost_m))

funded <- scored |> filter(cum_cost <= budget)
n_funded <- nrow(funded)

# Score against cost, funded projects highlighted (already written for you)
ggplot(scored, aes(x = cost_m, y = score, color = cum_cost <= budget, label = project)) +
  geom_point(size = 4) +
  geom_text(hjust = "inward", vjust = -1, size = 3, show.legend = FALSE) +
  scale_color_manual(values = c("TRUE" = "#2e9b4e", "FALSE" = "#9aa0a6"),
                     labels = c("TRUE" = "Funded", "FALSE" = "Not funded"), name = NULL) +
  scale_x_log10() +
  labs(x = "Cost ($ million, log scale)", y = "Weighted score", title = "Project scores and the $60M program") +
  theme_minimal()
```

##  Python

`weights = {"safety": 0.40, "mobility": 0.35, "equity": 0.25} budget = 60 # $ million scored = ( projects .assign(score=lambda d: d["safety"] * weights["safety"] + d["mobility"] * weights["mobility"] + d["equity"] * weights["equity"]) .sort_values("score", ascending=False) .assign(cum_cost=lambda d: d["cost_m"].cumsum()) ) funded = scored[scored["cum_cost"] <= budget] n_funded = len(funded) # Score against cost, funded projects highlighted (already written for you) fig, ax = plt.subplots(figsize=(6, 4)) is_funded = scored["cum_cost"] <= budget ax.scatter(scored["cost_m"], scored["score"], s=60, c=np.where(is_funded, "#2e9b4e", "#9aa0a6")) ax.set_xscale("log") ax.set_xlabel("Cost ($ million, log scale)") ax.set_ylabel("Weighted score") ax.set_title("Project scores and the $60M program") plt.tight_layout() plt.show()`

``` python
weights = {"safety": 0.40, "mobility": 0.35, "equity": 0.25}
budget = 60  # $ million

scored = (
    projects
    .assign(score=lambda d: d["safety"] * weights["safety"] + d["mobility"] * weights["mobility"] + d["equity"] * weights["equity"])
    .sort_values("score", ascending=False)
    .assign(cum_cost=lambda d: d["cost_m"].cumsum())
)

funded = scored[scored["cum_cost"] <= budget]
n_funded = len(funded)

# Score against cost, funded projects highlighted (already written for you)
fig, ax = plt.subplots(figsize=(6, 4))
is_funded = scored["cum_cost"] <= budget
ax.scatter(scored["cost_m"], scored["score"], s=60,
           c=np.where(is_funded, "#2e9b4e", "#9aa0a6"))
ax.set_xscale("log")
ax.set_xlabel("Cost ($ million, log scale)")
ax.set_ylabel("Weighted score")
ax.set_title("Project scores and the $60M program")
plt.tight_layout()
plt.show()
```

### Question 3: Map the Crash Rate 🗺️

The `region` layer holds county polygons with a synthetic crash rate per 10,000 residents. Find the county with the highest rate, then draw a choropleth that fills each county by its crash rate. (Maps use the `sf` package, so this one is R only.)

`# The county with the highest crash rate worst_county <- region$county[which.max(region$crash_rate)] # A choropleth of the crash rate p <- ggplot(region) + geom_sf(aes(fill = crash_rate), color = "white", linewidth = 0.2) + scale_fill_viridis_c(option = "magma", direction = -1, name = "Crashes per\n10,000 residents") + labs(title = "Synthetic crash rate by county") + theme_void() p`

``` r
# The county with the highest crash rate
worst_county <- region$county[which.max(region$crash_rate)]

# A choropleth of the crash rate
p <- ggplot(region) +
  geom_sf(aes(fill = crash_rate), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "magma", direction = -1, name = "Crashes per\n10,000 residents") +
  labs(title = "Synthetic crash rate by county") +
  theme_void()

p
```

### Question 4: Build a Trip Table 🧮

Use the gravity model for all five zones at once. Friction is `travel_time^-2`. Each cell of the trip table is the zone’s productions, shared across destinations in proportion to `attractions * friction`. Build the friction matrix and the trip table, then check the heatmap.

##  R

`friction <- tt^-2 # Attractions weighted by friction, for every origin and destination weighted <- sweep(friction, 2, attractions, "*") # Share each origin's productions across destinations trips <- productions * weighted / rowSums(weighted) round(trips) # The trip table as a heatmap (already written for you) as.data.frame(as.table(round(trips))) |> ggplot(aes(x = Var2, y = Var1, fill = Freq)) + geom_tile(color = "white") + geom_text(aes(label = Freq), size = 3.5) + scale_fill_gradient(low = "#eef6f8", high = "#5aa0b4", name = "Trips") + scale_y_discrete(limits = rev) + labs(x = "Destination", y = "Origin", title = "Gravity model trip table") + theme_minimal()`

``` r
friction <- tt^-2

# Attractions weighted by friction, for every origin and destination
weighted <- sweep(friction, 2, attractions, "*")

# Share each origin's productions across destinations
trips <- productions * weighted / rowSums(weighted)

round(trips)

# The trip table as a heatmap (already written for you)
as.data.frame(as.table(round(trips))) |>
  ggplot(aes(x = Var2, y = Var1, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Freq), size = 3.5) +
  scale_fill_gradient(low = "#eef6f8", high = "#5aa0b4", name = "Trips") +
  scale_y_discrete(limits = rev) +
  labs(x = "Destination", y = "Origin", title = "Gravity model trip table") +
  theme_minimal()
```

##  Python

`friction = tt**-2.0 # Attractions weighted by friction, for every origin and destination weighted = friction * attractions # Share each origin's productions across destinations trips = productions[:, None] * weighted / weighted.sum(axis=1, keepdims=True) # The trip table as a heatmap (already written for you) fig, ax = plt.subplots(figsize=(6, 4.5)) im = ax.imshow(trips, cmap="GnBu", vmax=trips.max() * 1.4) ax.set_xticks(range(5), zones, rotation=30, ha="right") ax.set_yticks(range(5), zones) for i in range(5): for j in range(5): ax.text(j, i, f"{trips[i, j]:.0f}", ha="center", va="center", fontsize=8) ax.set_xlabel("Destination") ax.set_ylabel("Origin") ax.set_title("Gravity model trip table") fig.colorbar(im, label="Trips") plt.tight_layout() plt.show()`

``` python
friction = tt**-2.0

# Attractions weighted by friction, for every origin and destination
weighted = friction * attractions

# Share each origin's productions across destinations
trips = productions[:, None] * weighted / weighted.sum(axis=1, keepdims=True)

# The trip table as a heatmap (already written for you)
fig, ax = plt.subplots(figsize=(6, 4.5))
im = ax.imshow(trips, cmap="GnBu", vmax=trips.max() * 1.4)
ax.set_xticks(range(5), zones, rotation=30, ha="right")
ax.set_yticks(range(5), zones)
for i in range(5):
    for j in range(5):
        ax.text(j, i, f"{trips[i, j]:.0f}", ha="center", va="center", fontsize=8)
ax.set_xlabel("Destination")
ax.set_ylabel("Origin")
ax.set_title("Gravity model trip table")
fig.colorbar(im, label="Trips")
plt.tight_layout()
plt.show()
```

------------------------------------------------------------------------

> **TIP:**
>
> **Nice work: you screened a corridor network, ranked a program of projects, built a trip table and mapped the results.** 🏆

*P.S. - If you got this far, you are definitely not lost anymore. That is a full regional planning workflow in four questions.*

------------------------------------------------------------------------

*Built with [Quarto Live](https://r-wasm.github.io/quarto-live/), [WebR](https://docs.r-wasm.org/webr/latest/) and [Pyodide](https://pyodide.org/). All data is synthetic, apart from the county outlines from the sf package.*
