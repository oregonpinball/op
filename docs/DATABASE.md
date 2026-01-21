# Database Schema

This document describes the database model and schema setup for Open Pinball (OP).

## Overview

Open Pinball uses **SQLite3** with **Ecto** for database management. The schema is organized around managing pinball tournaments, leagues, seasons, players, and locations.

## Entity Relationship Diagram

```
User (users)
├── has_many :players (optional link)
├── has_many :leagues (as :author)
├── has_many :tournaments (as :organizer)
└── has_many :user_tokens (cascade delete)

Player (players)
├── belongs_to :user (optional)
├── has_many :standings (cascade delete)
└── has_many :rankings

League (leagues)
├── belongs_to :user (as :author)
└── has_many :seasons

Season (seasons)
├── belongs_to :league
├── has_many :rankings
└── has_many :tournaments

Ranking (rankings)
├── belongs_to :player
└── belongs_to :season

Tournament (tournaments)
├── belongs_to :user (as :organizer, nilify on delete)
├── belongs_to :season (nilify on delete)
├── belongs_to :location (nilify on delete)
└── has_many :standings (cascade delete)

Standing (standings)
├── belongs_to :tournament (cascade delete)
└── belongs_to :player (cascade delete)

Location (locations)
└── has_many :tournaments
```

## Schemas

### User (`users`)

Authentication and user management.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `email` | string | UNIQUE, NOT NULL, case-insensitive |
| `hashed_password` | string | |
| `confirmed_at` | utc_datetime | Nullable |
| `role` | enum | `:system_admin`, `:td`, `:player` (default) |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

**Validations:**
- Email required, must contain `@`, no spaces, max 160 chars
- Password required, 8-72 characters, hashed with Bcrypt

---

### UserToken (`users_tokens`)

Session and email verification token management.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `user_id` | integer | FK → users.id, NOT NULL, cascade delete |
| `token` | binary | NOT NULL, 32 bytes |
| `context` | string | NOT NULL |
| `sent_to` | string | |
| `authenticated_at` | utc_datetime | |
| `inserted_at` | utc_datetime | |

**Token Expiry:**
- Session tokens: 14 days
- Magic link tokens: 15 minutes
- Email change tokens: 7 days

---

### Player (`players`)

Individual pinball players.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `external_id` | string | Indexed |
| `name` | string | NOT NULL |
| `slug` | string | Indexed, auto-generated |
| `user_id` | integer | FK → users.id, optional |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

**Design Note:** Players are retained even if user account is deleted for historical record preservation.

---

### Location (`locations`)

Physical venues for tournaments.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `external_id` | string | UNIQUE |
| `name` | string | NOT NULL |
| `slug` | string | UNIQUE, auto-generated |
| `address` | string | |
| `address_2` | string | |
| `city` | string | |
| `state` | string | |
| `country` | string | |
| `postal_code` | string | |
| `latitude` | float | |
| `longitude` | float | |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

---

### League (`leagues`)

Container for seasons and competitive structure.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `name` | string | NOT NULL, 1-255 chars |
| `description` | text | HTML-formatted |
| `slug` | string | UNIQUE, 2-255 chars, auto-generated |
| `author_id` | integer | FK → users.id, NOT NULL |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

---

### Season (`seasons`)

Time-bounded competitive period within a league.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `name` | string | NOT NULL, 1-255 chars |
| `description` | text | HTML-formatted |
| `slug` | string | UNIQUE, 2-255 chars, auto-generated |
| `start_at` | utc_datetime | |
| `end_at` | utc_datetime | Must be after `start_at` |
| `league_id` | integer | FK → leagues.id, NOT NULL |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

---

### Ranking (`rankings`)

Player rankings within a specific season using the Glicko rating system.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `player_id` | integer | FK → players.id, NOT NULL |
| `season_id` | integer | FK → seasons.id, NOT NULL |
| `is_rated` | boolean | Default: false |
| `rating` | float | Default: 1500.0, ≥ 0 |
| `rating_deviation` | float | Default: 200.0 |
| `ranking` | integer | > 0 |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

**Constraints:**
- Unique composite index on `(player_id, season_id)`

---

### Tournament (`tournaments`)

Individual tournament events.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `external_id` | string | |
| `external_url` | string | |
| `name` | string | NOT NULL |
| `slug` | string | UNIQUE, auto-generated |
| `description` | text | HTML-formatted |
| `start_at` | utc_datetime | NOT NULL |
| `tgp_config` | map | JSON config |
| `event_booster` | enum | `:none` (default), `:certified`, `:certified_plus`, `:championship_series`, `:major` |
| `qualifying_format` | enum | `:none` (default), `:single_elimination`, `:double_elimination`, `:match_play`, `:best_game`, `:card_qualifying`, `:pin_golf`, `:flip_frenzy`, `:strike_format`, `:target_match_play`, `:hybrid` |
| `base_value` | float | ≥ 0 |
| `tva_rating` | float | ≥ 0 |
| `tva_ranking` | float | ≥ 0 |
| `total_tva` | float | ≥ 0 |
| `tgp` | float | ≥ 0 |
| `event_booster_multiplier` | float | |
| `first_place_value` | float | ≥ 0 |
| `organizer_id` | integer | FK → users.id |
| `season_id` | integer | FK → seasons.id |
| `location_id` | integer | FK → locations.id |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

---

### Standing (`standings`)

Individual player results within a tournament.

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | integer | PK |
| `tournament_id` | integer | FK → tournaments.id, NOT NULL, cascade delete |
| `player_id` | integer | FK → players.id, NOT NULL, cascade delete |
| `position` | integer | ≥ 1 |
| `is_finals` | boolean | Default: false |
| `linear_points` | float | Default: 0.0, ≥ 0 |
| `dynamic_points` | float | Default: 0.0, ≥ 0 |
| `total_points` | float | |
| `decayed_points` | float | |
| `efficiency` | float | |
| `age_in_days` | integer | Default: 0, ≥ 0 |
| `decay_multiplier` | float | Default: 1.0 |
| `inserted_at` | utc_datetime | |
| `updated_at` | utc_datetime | |

---

## Key Design Patterns

### Sluggable Module

Auto-generates URL-safe slugs using Nanoid for Players, Leagues, Seasons, Locations, and Tournaments.

### Scope Pattern

`OP.Accounts.Scope` struct carries user context throughout the application for role-based authorization.

### Point System

Multi-component scoring system:
- **Linear points** - Stable component
- **Dynamic points** - Variable component
- **Total points** - Sum of linear + dynamic
- **Decayed points** - Adjusted over time with `decay_multiplier`

### Glicko Rating System

Players have `rating` and `rating_deviation` within seasons for competitive ranking.

### Cascade Behaviors

| Parent | Child | On Delete |
|--------|-------|-----------|
| User | UserToken | Cascade |
| Tournament | Standing | Cascade |
| Player | Standing | Cascade |
| Tournament | (organizer) | Nilify |
| Season | Tournament | Nilify |
| Location | Tournament | Nilify |

---

## File Paths

- **Schemas:** `lib/op/{accounts,locations,players,tournaments,leagues}/*.ex`
- **Migrations:** `priv/repo/migrations/*.exs`
- **Seeds:** `priv/repo/seeds.exs`
- **Utilities:** `lib/op/sluggable.ex`
