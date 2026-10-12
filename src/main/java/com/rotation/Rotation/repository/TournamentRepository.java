package com.rotation.Rotation.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.rotation.Rotation.entity.Tournament;

@Repository
public interface TournamentRepository extends JpaRepository<Tournament, Long> {

	@Modifying(flushAutomatically = true, clearAutomatically = true)
	@Query(value = "DELETE FROM tournament_teams WHERE team_id = :teamId", nativeQuery = true)
	int deleteTeamMemberships(@Param("teamId") Long teamId);

}
