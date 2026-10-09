CREATE TABLE tournament_standings (
    id BIGSERIAL PRIMARY KEY,
    tournament_id BIGINT NOT NULL,
    team_id BIGINT NOT NULL,
    played_matches INT DEFAULT 0,
    wins INT DEFAULT 0,
    draws INT DEFAULT 0,
    losses INT DEFAULT 0,
    points INT DEFAULT 0,
    won_sets INT DEFAULT 0,
    lost_sets INT DEFAULT 0,
    won_games INT DEFAULT 0,
    lost_games INT DEFAULT 0,
    game_difference INT DEFAULT 0,
    set_difference INT DEFAULT 0,
    CONSTRAINT fk_standing_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_standing_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
);
