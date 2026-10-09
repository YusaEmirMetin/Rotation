package com.rotation.Rotation.controller;

import com.rotation.Rotation.dto.StartMatchRequest;
import com.rotation.Rotation.entity.Match;
import com.rotation.Rotation.service.MatchService;
import com.rotation.Rotation.service.TournamentService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/matches")
@RequiredArgsConstructor
public class MatchController {

    private final MatchService matchService;
    private final TournamentService tournamentService;

    // POST /api/matches/start
    // Body: { "team1Name": "Takım A", "team2Name": "Takım B" }
    @PostMapping("/start")
    public ResponseEntity<Match> startMatch(@RequestBody Map<String, String> body) {
        String team1Name = body.get("team1Name");
        String team2Name = body.get("team2Name");
        Match match = matchService.startMatch(team1Name, team2Name);
        return ResponseEntity.ok(match);
    }

    // GET /api/matches/active — aktif maçı döner
    @GetMapping("/active")
    public ResponseEntity<Match> getActiveMatch() {
        return matchService.getActiveMatch()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }

    // POST /api/matches/{id}/score
    // Body: { "team": 1, "delta": 1 } → team 1'e +1 puan
    // Body: { "team": 1, "delta": -1 } → team 1'den -1 puan (uzun basış düzeltme)
    @PostMapping("/{id}/score")
    public ResponseEntity<Match> updateScore(
            @PathVariable Long id,
            @RequestBody Map<String, Integer> body) {
        int team = body.get("team");
        int delta = body.get("delta");
        Match updated = matchService.updateScore(id, team, delta);
        return ResponseEntity.ok(updated);
    }

    // POST /api/matches/{id}/finish — maçı bitirir
    @PostMapping("/{id}/finish")
    public ResponseEntity<Match> finishMatch(@PathVariable Long id) {
        Match finished = matchService.finishMatch(id);
        return ResponseEntity.ok(finished);
    }

    @PostMapping("/start-teams")
    public ResponseEntity<Match> startMatchFromTeams(@RequestBody StartMatchRequest request) {
        Match match = matchService.startMatchFromTeams(request.getTeam1Id(), request.getTeam2Id());
        return ResponseEntity.ok(match);
    }

    // Get All Matches
    @GetMapping("/history")
    public ResponseEntity<List<Match>> getMatchHistory() {
        return ResponseEntity.ok(matchService.getFinishedMatches());
    }

    // Delete Match
    @DeleteMapping("/{id}")
    public ResponseEntity<Match> deleteMatch(@PathVariable Long id) {
        matchService.deleteMatch(id);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/tournaments/{tournamentId}")
    public ResponseEntity<Match> createMatchFromTournament(@PathVariable Long tournamentId) {
        Match match = matchService.createMatchFromTournament(tournamentId);
        return ResponseEntity.ok(match);
    }
}
