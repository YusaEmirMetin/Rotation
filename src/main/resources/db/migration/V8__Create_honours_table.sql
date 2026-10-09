CREATE TABLE honours (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(255) NOT NULL,
    number INT NOT NULL,
    team_id BIGINT,
    player_id BIGINT,
    CONSTRAINT fk_honours_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT fk_honours_player FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);
