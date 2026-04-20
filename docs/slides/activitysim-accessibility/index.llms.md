# Accessibility in Activity Based Model

Pukar Bhandari

2026-04-19

ActivitySim Deep Dive · Session 2

# Initialization & *Accessibility*

How ActivitySim loads data, validates inputs, and  
computes the first aggregate measure of the model run.

Audience: Travel Demand Modelers

Focus: Initialization Components & Accessibility Model

Reference: ActivitySim v1.5.1

Context

From 4-Step to Activity-Based Modeling

4-Step Model

### Aggregate Flows

Trip generation: zone-level productions & attractions

Trip distribution: gravity model, zone-to-zone OD matrices

Mode choice: logit on aggregate OD pairs

Traffic assignment: flows on network links

→

Activity-Based Model

### Synthetic Individuals

Each person has a daily activity pattern, not a trip list

Tours link outbound + return trips around a primary activity

Choices are sequential and interdependent per person

Time of day, destination, mode decided together

**Key shift:** ActivitySim simulates *individuals*, not zone-level flows — but it still needs aggregate zone data (skims, land use, accessibility) as inputs to individual decisions.

How the System Works

The ActivitySim Execution Pipeline

① Setup & Initialization

todayinput_checker

initialize_landuse

initialize_households

initialize_los

initialize_tours

② Aggregate Measures

todaycompute_accessibility

Coverage today ↑

③ Disaggregate Behavioral Models

school_location_choice

work_location_choice

cdap (daily activity pattern)

mandatory_tour_frequency

tour_mode_choice

stop_frequency · trip_mode_choice

write_tables · track_skim_usage

Initialization

Four Data Processing Steps

1

### Initialize Land Use

Registers zonal employment and demographic data in the pipeline. First table loaded — sets the spatial foundation.

2

### Initialize Households & Persons

Lazy-loads household and person records. Annotates tables with derived variables like value-of-time. Resolves dependency chain via the inject system.

3

### Initialize LOS

Loads highway and transit skims from OMX files. In three-zone systems, pre-computes Transit Virtual Path Builder (TVPB) utilities and caches them.

4

### Initialize Tours

Pre-loads tour structures for implementations that define mandatory tours before behavioral models run. Ensures the tour table exists for downstream annotation.

**Important:** None of these steps predict behavior. They are **data pipeline steps** — loading, annotating, and registering data for the behavioral models that follow.

Step 1

Initialize Land Use

The land use table contains **zonal attributes** — employment counts, population, and other socioeconomic data indexed by zone ID. It is the first table loaded because nearly everything depends on it.

The **inject system** registers it lazily: it is not read from disk until first requested. Once loaded, it is cached in the pipeline for all downstream models.

\# settings.yaml — table registration  
input_table_list:  
  - tablename: land_use  
   filename: land_use.csv  
   index_col: zone_id  
   column_map:  
     ZONE: zone_id

zone_idTOTEMPRETEMPNTOTPOP

100114,8202,1408,320

10026,35089012,150

10031,20034022,400

100438,6005,8003,100

100578012019,200

Key Columns Used by Accessibility

TOTEMP Total employment

RETEMPN Retail trade employment

Step 2

Initialize Households & Persons

ActivitySim uses **dependency injection** — each model declares what data it needs, and the framework resolves dependencies automatically.

When `initialize_households` runs, it triggers a chain of lazy loads, annotates the tables with derived variables, and registers them in the pipeline.

**Restartability:** Because tables are loaded on-demand and checkpointed, a failed run can resume from any completed step — not restart from scratch.

Dependency Resolution Chain

initialize_households()

STEP

├─

needs: **persons** table

├─

needs: **households** table

└─

read_input_table("households.csv")

I/O

└─

read_input_table("persons.csv")

├─

needs: **land_use** table

cached

└─

annotate tables, set up RNG channels

Step 3

Initialize LOS — Skims & Network

### One-Zone System (TAZ)

Highway OMX skims: IVTT, distance, cost by time period (AM, MD, PM)

Transit OMX skims: IVT, initial wait, transfer wait, walk access/egress

All OD pairs at TAZ level

Skim matrix (TAZ × TAZ)

### Two-Zone System (MAZ + TAZ)

All one-zone skims, plus MAZ-to-MAZ walk & bike tables

Blended impedance near origins: MAZ→MAZ for short, TAZ→TAZ for longer

Origins/destinations at MAZ level; auto/transit at TAZ level

**Example blend formula:**  
MAZ_dist × (d/max_d) +  
TAZ_dist × (1 − d/max_d)

### Three-Zone System (MAZ + TAZ + TAP)

Adds TAP-to-TAP transit skims (boarding to alighting stop clusters)

MAZ-to-TAP walk & drive access/egress tables

**TVPB**: pre-computes all TAP→TAP path utilities by demographic segment & time period. Cached for reuse.

⚠ Three-zone approach being deprecated — new implementations should use one- or two-zone.

Step 4

Initialize Tours

In ActivitySim, travel is organized as **tours** — not individual trips. A tour begins and ends at home, with a primary destination and optional intermediate stops.

The Initialize Tours step pre-loads tour structures before behavioral models run. This ensures the tour table exists with the correct index and schema so downstream models can safely annotate and extend it.

\# Example: mandatory tours pre-defined per person  
tour_id: 10010001  \# person 1001, tour 1  
person_id: 1001  
tour_type: work  
tour_num: 1  
number_of_participants: 1

W

#### Mandatory — Work

Persons with work tours; departure, arrival, mode, and intermediate stops are all modeled

S

#### Mandatory — School

Children and students; destination choice for school location feeds into these tours

N

#### Non-Mandatory

Shopping, recreation, meals — generated later in the pipeline, not pre-initialized

J

#### Joint

Household members traveling together; requires coordination across person records

Optional — Runs First

Input Checker

The Input Checker validates your input data **before** anything else runs. It uses the **Pandera** Python library — you write the checks, ActivitySim runs them.

1

Copy `input_checks.py` and `enums.py` from example folder (prototype_mtc_extended)

2

Modify to match your data: column names, value ranges, referential integrity, categorical encodings

3

Add `input_checker` as the first model in `settings.yaml`

4

Checks can be **errors** (fatal) or **warnings** (logged but continue)

Input Data  
households.csv · persons.csv · land_use.csv · skims.omx

↓

input_checker  
Pandera validation · user-defined rules

↓

✓ All checks pass  
Pipeline continues

✗ Check fails  
Crash → input_checker.log

activitysim run -c configs -d data  
  -o output --data_model data_model

Part 2 of Today's Session

Accessibility

From any zone, how much employment can residents *realistically reach* — weighted by how hard it is to get there?

Origin-based

Aggregate · zone-level

Mode-specific

Time-period sensitive

One row per TAZ

Pre-computed once

In the 4-step model, accessibility is implicit in the gravity model's friction factors. **ActivitySim makes it explicit:** a pre-computed table of zonal measures that individual agents respond to in their location and destination choices.

The Calculation

The Accessibility Formula

Accessibility for origin zone i

A_(i) = ln (  Σ_(j)  Emp_(j)  ×  e^(−β·t_(ij))  )

Emp_j Employment at destination zone j (total or retail)

t_ij Round-trip travel time from i to j (mode & period specific)

β Decay parameter — steeper for walk, shallower for auto

ln(·) Log-sum compresses distribution, prevents high-density zones from dominating

Decay Function by Mode

Auto (shallow decay)

Transit (medium)

Walk (steep decay)

Three Time Periods

AM

6am – 10am

MD

10am – 3pm

PM

3pm – 7pm

What Goes In

Inputs & Outputs

Inputs

#### Highway Skims (3 periods)

OMX matrices. Required field: `TOLLTIMEDA` — drive-alone in-vehicle time for toll-willing autos

AM PeakMiddayPM Peak

#### Transit Skims (3 periods)

IVT · IWAIT · XWAIT · WACC · WAUX · WEGR

In-vehicleWaitWalk

#### Land Use — Employment

Zonal totals: `TOTEMP` (all employment), `RETEMPN` (retail only)

→

Outputs — 10 Measures per TAZ

#### Auto Accessibility

autoPeakRetailautoPeakTotalautoOffPeakRetailautoOffPeakTotal

#### Transit Accessibility

transitPeakRetailtransitPeakTotaltransitOffPeakRetailtransitOffPeakTotal

#### Non-Motorized (Walk)

nonMotorizedRetailnonMotorizedTotal

All measures are on a log scale · One row per TAZ · Minimum = 0

Why Position Matters

Where Accessibility Fits

Accessibility runs **immediately after land use is loaded** — before any person or household data. This is intentional: it is an **aggregate, zone-level calculation** that needs only skims and employment.

Once computed, the 10 accessibility measures are attached to the land use table and become available to every behavioral model as zone-level explanatory variables.

#### Used Downstream In:

- School location choice — transit access to schools
- Work location choice — auto & transit access to employment
- Non-mandatory destination choice — retail accessibility
- Mode choice — relative accessibility by mode

Pipeline Sequence

input_checker

initialize_landuse

compute_accessibility ← runs here

initialize_households

initialize_los & initialize_tvpb

accessibility table now available...

school_location_choice ↖ uses it

work_location_choice ↖ uses it

destination_choice ↖ uses it

Going Deeper

Three Types of Accessibility Measures

A

Aggregate

Pre-computed per zone. The log-sum-of-employment formula from `compute_accessibility`. One value per TAZ, per mode, per period. Feeds auto ownership, work location, free parking.

Zone-level · Fast · Already in ActivitySim

D

Disaggregate

Computed per person using mode-choice logsums. Theoretically consistent — cost and time both included. Captures who you are, not just where you live.

Person-level · Consistent · Expensive to retrofit

H

Ad Hoc

Convenience measures chosen for predictive fit: drive-time savings, raw auto IVT, etc. Works well for routine scenarios — breaks on novel policies that change time and cost in opposite directions.

Shortcut · Often predicts better · Inconsistency risk

→ The next slides explore what happens when these measures disagree — and why it matters for policy analysis

The Core Question

What Number Gets Used?

When a person in the model decides to own a car or choose a job location — what does the model use to represent "how easy is it to get around from here?" That number is the **accessibility measure**, and the choice matters enormously for novel policies.

4-Step TDM

Trip Distribution

Drive time (impedance)

Auto Ownership

Time savings vs. transit

Mode Choice

IVT + wait time

⚠ Each submodel picks its own shortcut — "ad hoc" measures chosen for fit, not consistency

VS

ActivitySim (ABM)

Auto Ownership

Aggregate accessibility *or*

Disaggregate logsum ✓

Work Location Choice

Zone accessibility *or*

Destination logsum ✓

Destination Choice

Mode choice logsum ✓

✓ One consistent spec — all submodels respond to the same policy signal

Does every part of your model respond *consistently* to the same policy change?

Ad Hoc Accessibility

The Salt Lake City Problem

**Scenario:** WFRC tests a downtown cordon toll. Driving into downtown becomes faster (less congestion) but costs more money.

WFRC auto ownership uses this ad hoc measure:

Accessibility = Auto time savings vs. transit

(minutes saved by driving — cost never appears)

🚗 Toll cost increase \$0

⏱ Time saving (min) 0 min

🏙️

Cordon Toll Introduced

Set the sliders →

↓

👁️

Ad Hoc Model Sees…

Adjust toll & time saving

↓

🤔

Model Predicts…

Waiting for input

The Consistent Alternative

Disaggregate Accessibility

The Logsum — expected best option across ALL modes

Logsum = ln \[ exp(V_(auto)) + exp(V_(transit)) + exp(V_(walk)) \]

where V_(auto) = β_(time) × travel_time + β_(cost) × travel_cost

Same spec as your mode choice model — cost is *already in it*

1

**Time AND cost are both included**  
Your mode choice model already has both. The logsum inherits everything — time, cost, transfers, parking.

2

**Computed per person, not per zone**  
Person A near transit ≠ Person B in a car-dependent suburb, even in the same zone. That's "disaggregate."

3

**Add a toll → logsum falls → car ownership falls**  
V_(auto) drops → logsum drops → auto ownership model responds correctly. All components stay in sync.

Logsum Calculator

Adjust parameters — watch how the logsum responds

Auto travel time (min) 20

Auto cost (\$) \$0

Transit time (min) 35

🚧 Cordon toll (\$) \$0

V_(auto)

—

V_(transit)

—

Logsum

—

Strategy A — Build it in

Include cost in accessibility during model development. Novel policies handled automatically. Higher upfront investment, lower application risk.

Strategy B — Intervene at application

Keep ad hoc measures but convert tolls to time-equivalents manually. Lower upfront cost, requires expert judgment at application time.

The Full Picture

Disaggregate Accessibility: Honest Tradeoffs

✓ Pros

⚙️

Consistent responses

A toll affects auto ownership, mode choice, and destination choice — all correctly, all from one spec. No component out of sync.

📈

Improves automatically

As your mode choice spec improves, accessibility improves too. No extra calibration work.

💰

Consumer surplus measure

Change in logsums = a rigorous benefit-cost measure. Peer reviewers and funding agencies respond well.

🎓

Theoretically sound

Derived from utility maximization theory. Defensible in academic and regulatory review.

✗ Cons

🐢

Computationally expensive

Computed per person, not per zone. Adds significant runtime on large models.

🔧

Retrofitting is painful

Adding the step is only half the job. You must also update every submodel using ad hoc measures — expensive and tedious.

⚠️

Ad hoc often predicts better!

Time savings may simply be more predictive of car ownership than the logsum. Theoretical consistency ≠ better fit.

🔍

Harder to debug

When submodels are tightly coupled through logsums, tracing unexpected results becomes more difficult.

Both strategies are legitimate. Build-in vs. intervene depends on your policy context and team capacity.

Summary

Key Takeaways

1

#### Initialization is data pipeline setup, not behavioral modeling

The four initialize steps load, validate, and annotate inputs so downstream models have clean, consistent data. Random seeds are set here for reproducibility.

2

#### Aggregate accessibility is zone-level and pre-computed

It translates skims + employment into zonal scores (log-sum formula) consumed by auto ownership, work location, and free parking models.

3

#### Ad hoc measures create inconsistent model responses to novel policies

If cost is missing from your accessibility term, a cordon toll can wrongly predict *more* car ownership — because the model only sees the time saving.

4

#### Disaggregate logsums are consistent — but not always better predictors

The logsum inherits time AND cost from your mode choice spec. But ad hoc measures often fit observed data better. Both Strategy A (build in) and B (intervene) are defensible.
