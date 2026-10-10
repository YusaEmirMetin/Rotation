package com.rotation.Rotation.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.entity.TournamentStanding;
import com.rotation.Rotation.repository.TeamRepository;
import com.rotation.Rotation.repository.TournamentRepository;
import com.rotation.Rotation.repository.TournamentStandingRepository;
import com.rotation.Rotation.entity.Team;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TournamentService {
    private final TournamentRepository tournamentRepository;
    private final TeamRepository teamRepository;
    private final TournamentStandingRepository tournamentStandingRepository;

    public Tournament createTournament(Tournament tournament) {
        return tournamentRepository.save(tournament);
    }

    public Tournament getTournamentById(Long id) {
        return tournamentRepository.findById(id).orElseThrow(() -> new RuntimeException("Tournament not found"));
    }

    public List<Tournament> getAllTournaments() {
        return tournamentRepository.findAll();
    }

    public void deleteTournament(Long id) {
        tournamentRepository.deleteById(id);
    }

    public Tournament updateTournament(Long id, Tournament tournament) {
        Tournament existingTournament = getTournamentById(id);
        existingTournament.setTournamentName(tournament.getTournamentName());
        existingTournament.setTournamentStatus(tournament.getTournamentStatus());
        return tournamentRepository.save(existingTournament);
    }

    public Tournament addTeamToTournament(Long tournamentId, Long teamId) {
        Tournament existingTournament = getTournamentById(tournamentId);
        Team existingTeam = teamRepository.findById(teamId)
                .orElseThrow(() -> new RuntimeException("Team not found"));

        // Takımı turnuvaya ekle
        existingTournament.getTeams().add(existingTeam);
        Tournament savedTournament = tournamentRepository.save(existingTournament);

        // Takım eklendiği an puan tablosunda (Standings) 0 puanla başlat
        TournamentStanding standing = TournamentStanding.builder()
                .tournament(savedTournament)
                .team(existingTeam)
                .playedMatches(0)
                .wins(0)
                .draws(0)
                .losses(0)
                .points(0)
                .wonSets(0)
                .lostSets(0)
                .wonGames(0)
                .lostGames(0)
                .gameDifference(0)
                .setDifference(0)
                .build();
        tournamentStandingRepository.save(standing);

        return savedTournament;
    }

}
