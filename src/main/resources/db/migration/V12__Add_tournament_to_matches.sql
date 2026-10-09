ALTER TABLE matches ADD COLUMN tournament_id BIGINT;
ALTER TABLE matches ADD CONSTRAINT fk_match_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE;
