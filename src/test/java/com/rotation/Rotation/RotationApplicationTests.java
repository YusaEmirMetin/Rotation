package com.rotation.Rotation;

import java.time.LocalDate;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.rotation.Rotation.entity.Player;
import com.rotation.Rotation.entity.Match;
import com.rotation.Rotation.entity.Referee;
import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.entity.TournamentStanding;
import com.rotation.Rotation.entity.enums.PlayerPosition;
import com.rotation.Rotation.entity.enums.TournamentStatus;
import com.rotation.Rotation.repository.PlayerRepository;
import com.rotation.Rotation.repository.MatchRepository;
import com.rotation.Rotation.repository.RefereeRepository;
import com.rotation.Rotation.repository.TeamRepository;
import com.rotation.Rotation.repository.TournamentRepository;
import com.rotation.Rotation.repository.TournamentStandingRepository;
import com.rotation.Rotation.service.PlayerService;
import com.rotation.Rotation.service.MatchService;
import com.rotation.Rotation.service.TeamService;

@SpringBootTest
class RotationApplicationTests {

	@Autowired
	private TeamRepository teamRepository;

	@Autowired
	private PlayerRepository playerRepository;

	@Autowired
	private MatchRepository matchRepository;

	@Autowired
	private RefereeRepository refereeRepository;

	@Autowired
	private MatchService matchService;

	@Autowired
	private PlayerService playerService;

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
	void refereeCanBeAssignedToMatch() {
		Referee referee = refereeRepository.saveAndFlush(Referee.builder()
				.firstName("Ada")
				.lastName("Yilmaz")
				.build());
		Match match = matchRepository.saveAndFlush(Match.builder()
				.team1Name("Team A")
				.team2Name("Team B")
				.build());

		Match assignedMatch = matchService.assignReferee(match.getId(), referee.getId());

		assertEquals(referee.getId(), assignedMatch.getReferee().getId());
		assertEquals("Yilmaz", matchRepository.findById(match.getId()).orElseThrow()
				.getReferee().getLastName());
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

	@Test
	@Transactional
	void playerCanBeUpdatedAndDeletedOnlyThroughOwningTeam() {
		Team team = new Team();
		team.setName("player-owner-" + UUID.randomUUID());
		team = teamRepository.saveAndFlush(team);

		Team otherTeam = new Team();
		otherTeam.setName("player-other-" + UUID.randomUUID());
		otherTeam = teamRepository.saveAndFlush(otherTeam);

		Player player = new Player();
		player.setFirstName("Ada");
		player.setLastName("Yilmaz");
		player.setJerseyNumber(7);
		player.setPosition(PlayerPosition.SETTER);
		player.setTeam(team);
		player = playerRepository.saveAndFlush(player);
		Long teamId = team.getId();
		Long otherTeamId = otherTeam.getId();
		Long playerId = player.getId();

		Player changes = new Player();
		changes.setFirstName("Ece");
		changes.setLastName("Demir");
		changes.setJerseyNumber(11);
		changes.setPosition(PlayerPosition.LIBERO);
		changes.setHeightCm(172);

		Player updated = playerService.updatePlayer(teamId, playerId, changes);
		assertEquals("Ece", updated.getFirstName());
		assertEquals("Demir", updated.getLastName());
		assertEquals(11, updated.getJerseyNumber());
		assertEquals(PlayerPosition.LIBERO, updated.getPosition());
		assertEquals(172, updated.getHeightCm());
		assertThrows(ResponseStatusException.class,
				() -> playerService.updatePlayer(otherTeamId, playerId, changes));
		assertThrows(ResponseStatusException.class,
				() -> playerService.deletePlayer(otherTeamId, playerId));
		assertTrue(playerRepository.existsById(playerId));

		playerService.deletePlayer(teamId, playerId);
		assertFalse(playerRepository.existsById(playerId));
	}

}
