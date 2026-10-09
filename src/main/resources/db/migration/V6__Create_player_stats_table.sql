CREATE TABLE player_stats (
    id BIGSERIAL PRIMARY KEY,
    match_id BIGINT NOT NULL,
    player_id BIGINT NOT NULL,
    point INT DEFAULT 0,
    assist INT DEFAULT 0,
    block INT DEFAULT 0,
    serve INT DEFAULT 0,
    reception INT DEFAULT 0,
    attack INT DEFAULT 0,
    error INT DEFAULT 0,
    CONSTRAINT fk_player_stats_match FOREIGN KEY (match_id) REFERENCES matches(id),
    CONSTRAINT fk_player_stats_player FOREIGN KEY (player_id) REFERENCES players(id)
);
