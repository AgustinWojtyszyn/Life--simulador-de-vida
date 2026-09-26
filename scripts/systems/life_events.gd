extends Node

# Extension points only: no mission/economy/progression systems in Phase 1.
signal interacted(kind: String, target_id: String)
signal location_changed(country_id: String, district_id: String, location: String)
signal profile_created(profile: PlayerProfile)
signal rested(home_id: String)
signal game_saved
