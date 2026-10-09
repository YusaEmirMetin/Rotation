package com.rotation.Rotation.service;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import java.util.List;
import com.rotation.Rotation.entity.Fixture;
import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.repository.FixtureRepository;
import com.rotation.Rotation.repository.TournamentRepository;
import com.rotation.Rotation.repository.TournamentStandingRepository;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;

@Service
@RequiredArgsConstructor
public class FixtureService {
    private final FixtureRepository fixtureRepository;
    private final TournamentRepository tournamentRepository;
    private final TournamentStandingRepository tournamentStandingRepository;

    public List<Fixture> getFixturesByTournamentWeek(Integer tournamentWeek) {
        return fixtureRepository.findByTournamentWeek(tournamentWeek);
    }

    public List<Fixture> findAll() {
        return fixtureRepository.findAll();
    }

    public List<Fixture> getFixturesByTournamentWeekAndMatchDay(Integer tournamentWeek, Integer matchDay) {
        return fixtureRepository.findByTournamentWeekAndMatchDay(tournamentWeek, matchDay);
    }

    public List<Fixture> getFixturesByTournamentId(Long tournamentId) {
        return fixtureRepository.findByTournamentId(tournamentId);
    }

    @Transactional
    public List<Fixture> generateFixturesForTournament(Long tournamentId) {
        Tournament tournament = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new RuntimeException("Tournament not found"));

        List<Team> teams = new ArrayList<>(tournament.getTeams());
        if (teams.size() < 2) {
            throw new RuntimeException("At least 2 teams are required to generate fixtures");
        }

        if (!fixtureRepository.findByTournamentId(tournamentId).isEmpty()) {
            throw new RuntimeException("Fixtures already generated for this tournament");
        }

        boolean hasDummy = false;
        Team dummy = null;
        if (teams.size() % 2 != 0) {
            dummy = new Team();
            dummy.setId(-1L);
            teams.add(dummy);
            hasDummy = true;
        }

        int numTeams = teams.size();
        int numRounds = numTeams - 1;
        int halfSize = numTeams / 2;

        List<Fixture> generatedFixtures = new ArrayList<>();
        List<Team> teamsCopy = new ArrayList<>(teams);
        teamsCopy.remove(0);

        for (int round = 0; round < numRounds; round++) {
            Team team1 = teams.get(0);
            Team team2 = teamsCopy.get(round % teamsCopy.size());
            
            if (team1.getId() != -1L && team2.getId() != -1L) {
                generatedFixtures.add(Fixture.builder()
                        .tournament(tournament)
                        .tournamentWeek(round + 1)
                        .matchDay(1)
                        .matchOrder(1)
                        .homeTeamId(team1.getId())
                        .awayTeamId(team2.getId())
                        .homeTeamScore(0)
                        .awayTeamScore(0)
                        .build());
            }

            for (int i = 1; i < halfSize; i++) {
                int firstIdx = (round + i) % teamsCopy.size();
                int secondIdx = (round + teamsCopy.size() - i) % teamsCopy.size();
                
                Team t1 = teamsCopy.get(firstIdx);
                Team t2 = teamsCopy.get(secondIdx);
                
                if (t1.getId() != -1L && t2.getId() != -1L) {
                    generatedFixtures.add(Fixture.builder()
                            .tournament(tournament)
                            .tournamentWeek(round + 1)
                            .matchDay(1)
                            .matchOrder(i + 1)
                            .homeTeamId(t1.getId())
                            .awayTeamId(t2.getId())
                            .homeTeamScore(0)
                            .awayTeamScore(0)
                            .build());
                }
            }
        }

        return fixtureRepository.saveAll(generatedFixtures);
    }
}