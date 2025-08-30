library(dplyr)

links <- creatures %>%
  distinct(creatureName) %>%
  left_join(select(lair_mobiles, creatureName, lairName), by = "creatureName") %>%
  left_join(select(static_spawns, mobile, x, z, y), by = c("creatureName" = "mobile")) %>%
  left_join(select(lair_spawn_groups, lairTemplateName, spawnGroupName), by = c("lairName" = "lairTemplateName")) # %>%
  # left_join(select(zones, spawnZone, name), by = c("spawnGroupName" = "spawnZone"))

creature_zone_status <- links %>%
  group_by(creatureName) %>%
  summarise(
    #has_zone       = any(!is.na(name)),
    has_group      = any(!is.na(spawnGroupName)),
    static_spawn   = any(!is.na(x), !is.na(y), !is.na(z)),
    n_lairs        = n_distinct(lairName, na.rm = TRUE),
    n_spawn_groups = n_distinct(spawnGroupName, na.rm = TRUE),
    #n_zones        = n_distinct(name, na.rm = TRUE),
    .groups = "drop"
  )

creatures_without_spawn_group <- creature_zone_status %>%
  filter(!has_group) %>%
  filter(!static_spawn) %>%
  select(creatureName, n_lairs, n_spawn_groups, static_spawn)
