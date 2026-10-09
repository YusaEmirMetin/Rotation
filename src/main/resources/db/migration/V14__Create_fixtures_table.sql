CREATE TABLE fixtures (
    id BIGSERIAL PRIMARY KEY,
    tournament_id BIGINT NOT NULL,
    tournament_week INT,
    match_day INT,
    match_order INT,
    home_team_id BIGINT,
    away_team_id BIGINT,
    home_team_score INT DEFAULT 0,
    away_team_score INT DEFAULT 0,
    CONSTRAINT fk_fixture_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE
);
