DROP TABLE IF EXISTS profiles;

CREATE TABLE profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    directory TEXT NOT NULL,
    base_name TEXT NOT NULL,
    channels TEXT NOT NULL,
    dapi_suffix TEXT NOT NULL,
    red_suffix TEXT NOT NULL,
    green_suffix TEXT NOT NULL,
    cyan_suffix TEXT NOT NULL,
    red_marker TEXT NOT NULL,
    green_marker TEXT NOT NULL,
    cyan_marker TEXT NOT NULL
);

ALTER TABLE profiles ADD COLUMN gastruloid_min_size INTEGER NOT NULL DEFAULT 6000;
