package com.rotation.Rotation.repository;

import com.rotation.Rotation.entity.TournamentStanding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TournamentStandingRepository extends JpaRepository<TournamentStanding, Long> {
    List<TournamentStanding> findByTournamentIdOrderByPointsDesc(Long tournamentId);
    java.util.Optional<TournamentStanding> findByTournamentIdAndTeamName(Long tournamentId, String teamName);
}
