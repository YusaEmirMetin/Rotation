package com.rotation.Rotation.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.rotation.Rotation.entity.Fixture;

public interface FixtureRepository extends JpaRepository<Fixture, Long> {
    List<Fixture> findByTournamentWeek(Integer tournamentWeek); 
    List<Fixture> findByTournamentWeekAndMatchDay(Integer tournamentWeek, Integer matchDay);
}
