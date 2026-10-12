package com.rotation.Rotation;

import java.time.LocalDate;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.entity.TournamentStanding;
import com.rotation.Rotation.entity.enums.TournamentStatus;
import com.rotation.Rotation.repository.TeamRepository;
import com.rotation.Rotation.repository.TournamentRepository;
import com.rotation.Rotation.repository.TournamentStandingRepository;
import com.rotation.Rotation.service.TeamService;

@SpringBootTest
class RotationApplicationTests {

	@Autowired
	private TeamRepository teamRepository;

	@Autowired
	private TournamentRepository tournamentRepository;

	@Autowired
	private TournamentStandingRepository tournamentStandingRepository;

	@Autowired
	private TeamService teamService;

	@Test
	void contextLoads() {
	}

	@Test
	@Transactional
	void deletingTeamRemovesTournamentMembershipAndStandings() {
		Team team = new Team();
		team.setName("delete-test-" + UUID.randomUUID());
		team = teamRepository.saveAndFlush(team);

		Tournament tournament = new Tournament();
		tournament.setTournamentName("delete-test-" + UUID.randomUUID());
		tournament.setTournamentType("LEAGUE");
		tournament.setTournamentStartDate(LocalDate.now());
		tournament.setTournamentEndDate(LocalDate.now().plusDays(1));
		tournament.setTournamentStatus(TournamentStatus.UPCOMING);
		tournament.getTeams().add(team);
		tournament = tournamentRepository.saveAndFlush(tournament);

		tournamentStandingRepository.saveAndFlush(TournamentStanding.builder()
				.tournament(tournament)
				.team(team)
				.build());

		Long teamId = team.getId();
		Long tournamentId = tournament.getId();
		teamService.deleteById(teamId);

		assertFalse(teamRepository.existsById(teamId));
		assertTrue(tournamentRepository.findById(tournamentId).orElseThrow().getTeams().isEmpty());
		assertTrue(tournamentStandingRepository.findByTournamentIdOrderByPointsDesc(tournamentId).isEmpty());
	}

}
