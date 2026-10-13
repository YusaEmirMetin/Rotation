CREATE TABLE referees (
    id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL
);

ALTER TABLE matches
    ADD COLUMN referee_id BIGINT,
    ADD CONSTRAINT fk_matches_referee
        FOREIGN KEY (referee_id) REFERENCES referees(id) ON DELETE SET NULL;