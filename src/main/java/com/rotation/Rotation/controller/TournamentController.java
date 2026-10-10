package com.rotation.Rotation.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.boot.actuate.endpoint.annotation.DeleteOperation;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.entity.TournamentStanding;
import com.rotation.Rotation.repository.TournamentStandingRepository;
import com.rotation.Rotation.service.TournamentService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/tournaments")
@RequiredArgsConstructor
public class TournamentController {
    private final TournamentService tournamentService;
    private final TournamentStandingRepository standingRepository;

    @PostMapping
    public Tournament createTournament(@RequestBody Tournament tournament) {
        return tournamentService.createTournament(tournament);
    }

    @GetMapping("/{id}")
    public Tournament getTournamentById(@PathVariable Long id) {
        return tournamentService.getTournamentById(id);
    }

    @GetMapping
    public List<Tournament> getAllTournaments() {
        return tournamentService.getAllTournaments();
    }

    @DeleteMapping("/{id}")
    public void deleteTournament(@PathVariable Long id) {
        tournamentService.deleteTournament(id);
    }

    @PutMapping("/{id}")
    public Tournament updateTournament(@PathVariable Long id, @RequestBody Tournament tournament) {
        return tournamentService.updateTournament(id, tournament);
    }

    @PostMapping("/{tournamentId}/teams/{teamId}")
    public Tournament addTeamToTournament(@PathVariable Long tournamentId, @PathVariable Long teamId) {
        return tournamentService.addTeamToTournament(tournamentId, teamId);
    }

    @GetMapping("/{tournamentId}/standings")
    public List<TournamentStanding> getTournamentStandings(@PathVariable Long tournamentId) {
        return standingRepository.findByTournamentIdOrderByPointsDesc(tournamentId);
    }

    @DeleteMapping
    public void deleteTournament(@RequestBody Tournament tournament) {
        tournamentService.deleteTournament(tournament.getId());
    }

    @DeleteMapping("/{tournamentId}/teams/{teamId}")
    public Tournament removeTeamFromTournament(@PathVariable Long tournamentId, @PathVariable Long teamId) {
        return tournamentService.removeTeamFromTournament(tournamentId, teamId);
    }
}
