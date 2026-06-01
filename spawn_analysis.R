# spawn_analysis.R
#
# Second-tier spatial analysis for SWG creature spawns.
#
# Models, from the extracted CSVs, *where you will actually find a creature* and
# how overlapping spawn zones change your odds. Grounded in the Core3 spawn
# mechanics (see CLAUDE.md / the SpawnArea logic):
#
#   * A spawn REGION (zones.csv, one physical area) references one or more spawn
#     GROUPS. Core3 merges all their lairs into a single weighted list and caps
#     the region at `maxSpawnLimit` concurrent lairs.
#   * Each freed slot is re-rolled weighted-random, so at steady state the live
#     lair population's composition is ~proportional to `weighting`.
#   * Overlapping regions spawn INDEPENDENTLY -> abundance is additive, but the
#     *concentration* of any one creature falls as another region adds clutter.
#
# Core quantities (per region R, lair template T with region weight w_T,
# region total weight W_R, region cap L_R, and lair_mobiles count count_{C,T}):
#
#   E[lairs of T in R]      ~= L_R * w_T / W_R
#   E[creatures of C in R]  ~= (L_R / W_R) * sum_{T contains C} w_T * count_{C,T}
#   concentration_R(C)       = E[C in R] / E[all creatures in R]   (L_R/W_R cancels)
#
# Across overlapping regions at a point p:
#   abundance(C, p)     = sum_{R covers p} E[C in R]              (additive)
#   concentration(C, p) = abundance(C, p) / sum_{R covers p} E[all in R]
#
# Assumptions / caveats: assumes regions stay saturated (true for trafficked
# newbie/city areas, weaker for remote ones); ignores differing lair lifetimes;
# treats placement-crowding qualitatively. Numbers are best read as relative.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

# ---- data loading ----------------------------------------------------------

load_spawn_data <- function(dir = ".") {
  list(
    zones = read_csv(file.path(dir, "zones.csv"), show_col_types = FALSE),
    groups = read_csv(file.path(dir, "lair_spawn_groups.csv"), show_col_types = FALSE),
    mobiles = read_csv(file.path(dir, "lair_mobiles.csv"), show_col_types = FALSE)
  )
}

# A spawn region is one physical area; the same area can list several spawn
# groups (multiple zones.csv rows sharing name+geometry). Collapse to regions.
REGION_KEYS <- c("planet", "name", "zoneType", "x", "y", "x2", "y2", "r", "r1", "r2", "maxSpawnLimit")

# ---- region model ----------------------------------------------------------

# Returns a list:
#   regions: one row per physical spawn region, with weight total, expected
#            total creatures, centroid, and is_world flag.
#   region_creature: region_id x creatureName -> abundance (E[C in R]).
build_region_model <- function(planet, data = load_spawn_data()) {
  zones <- data$zones %>%
    filter(planet == !!planet, !is.na(spawnZone), spawnZone != "",
           !is.na(maxSpawnLimit))

  if (nrow(zones) == 0) {
    return(list(regions = tibble(), region_creature = tibble()))
  }

  # Assign a stable region_id per physical area (bitmask is constant per area).
  regions_base <- zones %>%
    group_by(across(all_of(REGION_KEYS))) %>%
    summarise(zoneBitmask = first(zoneBitmask), .groups = "drop") %>%
    mutate(region_id = row_number(),
           # exact token match: WORLDSPAWNAREA is a substring of NOWORLDSPAWNAREA
           is_world = vapply(strsplit(zoneBitmask, " \\+ "),
                             function(t) "WORLDSPAWNAREA" %in% trimws(t), logical(1)))

  # Map each region to its set of spawn groups.
  region_groups <- zones %>%
    left_join(regions_base %>% select(all_of(REGION_KEYS), region_id),
              by = REGION_KEYS) %>%
    distinct(region_id, spawnGroupName = spawnZone)

  # Region weighted lair list: a lair listed in several of a region's groups has
  # its weighting summed (Core3 concatenates each group's entries).
  region_lairs <- region_groups %>%
    inner_join(data$groups %>% select(spawnGroupName, lairTemplateName, weighting),
               by = "spawnGroupName", relationship = "many-to-many") %>%
    group_by(region_id, lairTemplateName) %>%
    summarise(w = sum(weighting), .groups = "drop")

  # W_R: total weight per region.
  region_W <- region_lairs %>%
    group_by(region_id) %>%
    summarise(W = sum(w), .groups = "drop")

  # Expand lairs to creatures with per-lair counts.
  lair_creatures <- data$mobiles %>%
    select(lairTemplateName = lairName, creatureName, count) %>%
    mutate(count = ifelse(is.na(count) | count <= 0, 1, count))

  # Weighted creature contribution per region:
  #   contrib_{R,C} = sum_{T contains C} w_T * count_{C,T}
  region_creature_w <- region_lairs %>%
    inner_join(lair_creatures, by = "lairTemplateName", relationship = "many-to-many") %>%
    group_by(region_id, creatureName) %>%
    summarise(contrib = sum(w * count), .groups = "drop")

  # E[all creatures in R] uses the same contrib summed over all creatures.
  region_total_contrib <- region_creature_w %>%
    group_by(region_id) %>%
    summarise(total_contrib = sum(contrib), .groups = "drop")

  regions <- regions_base %>%
    left_join(region_W, by = "region_id") %>%
    left_join(region_total_contrib, by = "region_id") %>%
    mutate(
      maxSpawnLimit = as.numeric(maxSpawnLimit),
      # E[all in R] = (L_R / W_R) * total_contrib
      expected_total = ifelse(W > 0, maxSpawnLimit / W * total_contrib, 0),
      cx = x, cy = y  # centroid (circles/rings centred on x,y)
    )
  # Rectangle centroid is the midpoint of the bounds.
  regions <- regions %>%
    mutate(cx = ifelse(zoneType == "rectangle" & !is.na(x2), (x + x2) / 2, cx),
           cy = ifelse(zoneType == "rectangle" & !is.na(y2), (y + y2) / 2, cy))

  # E[C in R] = (L_R / W_R) * contrib_{R,C}
  region_creature <- region_creature_w %>%
    left_join(regions %>% select(region_id, maxSpawnLimit, W), by = "region_id") %>%
    mutate(abundance = ifelse(W > 0, maxSpawnLimit / W * contrib, 0)) %>%
    select(region_id, creatureName, abundance)

  list(regions = regions, region_creature = region_creature)
}

# ---- spatial arrangement ---------------------------------------------------

# Convert one region row to an sf polygon in game coordinates. Circles/rings are
# approximated as n-gons; rectangles use their bounds. Returns NULL if invalid.
region_to_polygon <- function(zoneType, x, y, x2, y2, r, r1, r2, nseg = 48) {
  circle_poly <- function(cx, cy, rad) {
    ang <- seq(0, 2 * pi, length.out = nseg + 1)
    ring <- cbind(cx + rad * cos(ang), cy + rad * sin(ang))
    ring[nrow(ring), ] <- ring[1, ]  # force exact closure (avoid FP drift)
    sf::st_polygon(list(ring))
  }
  if (zoneType == "circle" && !is.na(r)) {
    return(circle_poly(x, y, r))
  } else if (zoneType == "rectangle" && !is.na(x2) && !is.na(y2)) {
    xs <- sort(c(x, x2)); ys <- sort(c(y, y2))
    return(sf::st_polygon(list(rbind(
      c(xs[1], ys[1]), c(xs[2], ys[1]), c(xs[2], ys[2]),
      c(xs[1], ys[2]), c(xs[1], ys[1])))))
  } else if (zoneType == "ring" && !is.na(r1) && !is.na(r2)) {
    outer <- circle_poly(x, y, max(r1, r2))
    inner <- circle_poly(x, y, min(r1, r2))
    return(sf::st_difference(outer, inner))
  }
  NULL
}

# Compute the planar overlay of a planet's drawable spawn regions. Returns a
# tibble of intersection PIECES, each tagged with the set of regions that cover
# it. World-spawn areas (planet-wide) are excluded from the overlay -- they
# blanket everything -- and surfaced separately as a baseline by the caller.
#
# Each piece carries: member region_ids, centroid (cx, cy), area, the number of
# overlapping regions, and combined_expected_total (sum of members' E[all]).
build_intersections <- function(regions, min_overlap = 2) {
  drawable <- regions %>% filter(!is_world)
  if (nrow(drawable) < 2) return(tibble())

  polys <- lapply(seq_len(nrow(drawable)), function(i) {
    z <- drawable[i, ]
    region_to_polygon(z$zoneType, z$x, z$y, z$x2, z$y2, z$r, z$r1, z$r2)
  })
  keep <- !vapply(polys, is.null, logical(1))
  drawable <- drawable[keep, ]
  polys <- polys[keep]
  if (length(polys) < 2) return(tibble())

  sfobj <- sf::st_sf(idx = seq_along(polys),
                     geometry = sf::st_make_valid(sf::st_sfc(polys)))

  # Self-intersection yields every distinct overlay piece. On an sf object sf
  # adds an `origins` column listing the indices of the regions covering it.
  pieces <- suppressWarnings(sf::st_intersection(sfobj))
  if (is.null(pieces$origins)) return(tibble())

  region_ids <- drawable$region_id
  expected_by_idx <- drawable$expected_total

  rows <- lapply(seq_len(nrow(pieces)), function(i) {
    idx <- pieces$origins[[i]]
    if (length(idx) < min_overlap) return(NULL)
    geom <- sf::st_geometry(pieces)[[i]]
    if (length(geom) == 0 || sf::st_is_empty(sf::st_sfc(geom))) return(NULL)
    ctr <- sf::st_coordinates(sf::st_centroid(sf::st_sfc(geom)))
    tibble(
      piece_id = i,
      member_region_ids = list(region_ids[idx]),
      member_names = list(drawable$name[idx]),
      n_overlap = length(idx),
      cx = ctr[1, 1], cy = ctr[1, 2],
      area = as.numeric(sf::st_area(sf::st_sfc(geom))),
      combined_expected_total = sum(expected_by_idx[idx])
    )
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0) return(tibble())
  bind_rows(rows)
}

# ---- assembly for the map --------------------------------------------------

# Build the full per-planet payload the map embeds for client-side creature
# search: region metadata, the flat region->creature abundance table (the JS
# builds its own index), and the top intersection pieces. `top_intersections`
# caps how many overlap pieces to keep (largest by area) so the JSON stays small.
build_planet_spawn_model <- function(planet, data = load_spawn_data(),
                                      top_intersections = 60) {
  m <- build_region_model(planet, data)
  if (nrow(m$regions) == 0) {
    return(list(regions = tibble(), region_creature = tibble(), pieces = tibble()))
  }

  pieces <- build_intersections(m$regions)
  if (nrow(pieces) > 0) {
    pieces <- pieces %>% arrange(desc(area)) %>% head(top_intersections)
  }

  list(regions = m$regions,
       region_creature = m$region_creature %>% filter(abundance > 0),
       pieces = pieces)
}
