CREATE TABLE tournament_teams (
    tournament_id BIGINT NOT NULL,
    team_id BIGINT NOT NULL,
    PRIMARY KEY (tournament_id, team_id),
    CONSTRAINT fk_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
);
