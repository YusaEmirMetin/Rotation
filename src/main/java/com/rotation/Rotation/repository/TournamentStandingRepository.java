package com.rotation.Rotation.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.rotation.Rotation.entity.TournamentStanding;

@Repository
public interface TournamentStandingRepository extends JpaRepository<TournamentStanding, Long> {
    List<TournamentStanding> findByTournamentIdOrderByPointsDesc(Long tournamentId);
    java.util.Optional<TournamentStanding> findByTournamentIdAndTeamName(Long tournamentId, String teamName);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("DELETE FROM TournamentStanding standing WHERE standing.team.id = :teamId")
    int deleteByTeamId(@Param("teamId") Long teamId);
}
