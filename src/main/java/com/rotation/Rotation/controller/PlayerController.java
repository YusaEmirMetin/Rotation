package com.rotation.Rotation.controller;

import com.rotation.Rotation.entity.Player;
import com.rotation.Rotation.service.PlayerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
// RESTful standartlarına göre oyuncular bir takımın alt kaynağıdır.
// (Sub-resource)
@RequestMapping("/api/teams/{teamId}/players")
@RequiredArgsConstructor
public class PlayerController {

    private final PlayerService playerService;

    // POST /api/teams/1/players
    @PostMapping
    public ResponseEntity<Player> addPlayer(@PathVariable Long teamId, @RequestBody Player player) {
        Player createdPlayer = playerService.addPlayerToTeam(teamId, player);
        return new ResponseEntity<>(createdPlayer, HttpStatus.CREATED);
    }

    // GET /api/teams/1/players
    @GetMapping
    public ResponseEntity<List<Player>> getPlayersByTeamId(@PathVariable Long teamId) {
        List<Player> players = playerService.getPlayersByTeamId(teamId);
        return ResponseEntity.ok(players);
    }

    // Get /api/players
    @GetMapping("/all")
    public ResponseEntity<List<Player>> getAllPlayers() {
        List<Player> players = playerService.getAllPlayers();
        return ResponseEntity.ok(players);
    }

    // Delete /api/players/id
    @DeleteMapping("/{playerId}")
    public ResponseEntity<Void> deletePlayer(@PathVariable Long playerId) {
        playerService.deletePlayer(playerId);
        return ResponseEntity.noContent().build();
    }

    // Get /api/players/value/{playerId}
    @GetMapping("/value/{playerId}")
    public ResponseEntity<Double> getPlayerValue(@PathVariable Long playerId) {
        return ResponseEntity.ok(playerService.getPlayerValue(playerId));
    }

    // Get /api/players/id
    @GetMapping("/{playerId}")
    public ResponseEntity<Player> getPlayerById(@PathVariable Long playerId) {
        return ResponseEntity.ok(playerService.getPlayerById(playerId));
    }

    // Update /api/players/id
    /*
     * @PutMapping("/{playerId}")
     * public ResponseEntity<Player> updatePlayer(@PathVariable Long
     * playerId, @RequestBody Player player){
     * Player updatedPlayer = playerService.updatePlayer(playerId, player);
     * return ResponseEntity.ok(updatedPlayer);
     * }
     */
}
