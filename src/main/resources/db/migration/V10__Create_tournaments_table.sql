CREATE TABLE tournaments (
    id BIGSERIAL PRIMARY KEY,
    tournament_name VARCHAR(255) NOT NULL,
    tournament_type VARCHAR(255) NOT NULL,
    tournament_start_date DATE NOT NULL,
    tournament_end_date DATE NOT NULL,
    tournament_status VARCHAR(50) NOT NULL
);