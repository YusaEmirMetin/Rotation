package com.rotation.Rotation.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.rotation.Rotation.entity.PlayerStats;
import com.rotation.Rotation.service.PlayerStatsService;

import java.util.List;

@RestController 
@RequestMapping("/api/player-stats")
public class PlayerStatsController {
    
    @Autowired
    private PlayerStatsService playerStatsService;

    @GetMapping
    public List<PlayerStats> getAllPlayerStats() {
        return playerStatsService.getAllPlayerStats();
    }

    @GetMapping("/{matchId}")
    public List<PlayerStats> getPlayerStatsByMatchId(@PathVariable Long matchId) {
        return playerStatsService.getPlayerStatsByMatchId(matchId);
    }

    // Antrenör sayıya tıkladığında çağrılacak
    @PostMapping("/point")
    public void recordPoint(@RequestParam Long matchId, @RequestParam Long playerId) {
        playerStatsService.recordPoint(matchId, playerId);
    }

    // Antrenör hataya tıkladığında çağrılacak
    @PostMapping("/error")
    public void recordError(@RequestParam Long matchId, @RequestParam Long playerId) {
        playerStatsService.recordError(matchId, playerId);
    }
}
