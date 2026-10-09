package com.rotation.Rotation.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.repository.TeamRepository;
import com.rotation.Rotation.repository.TournamentRepository;
import com.rotation.Rotation.entity.Team;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TournamentService {
    private final TournamentRepository tournamentRepository;
    private final TeamRepository teamRepository;

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
        existingTournament.getTeams().add(existingTeam);
        return tournamentRepository.save(existingTournament);
    }
}
