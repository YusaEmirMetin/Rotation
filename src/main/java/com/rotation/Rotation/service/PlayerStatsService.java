package com.rotation.Rotation.service;

import org.springframework.stereotype.Service;

import com.rotation.Rotation.entity.PlayerStats;
import com.rotation.Rotation.repository.MatchRepository;
import com.rotation.Rotation.repository.PlayerRepository;
import com.rotation.Rotation.repository.PlayerStatsRepository;

import java.util.List;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PlayerStatsService {

    private final PlayerStatsRepository playerStatsRepository;
    private final MatchRepository matchRepository;
    private final PlayerRepository playerRepository;

    private PlayerStats findOrCreateStats(Long matchId, Long playerId) {
        return playerStatsRepository.findByMatchIdAndPlayerId(matchId, playerId)
                .orElseGet(() -> {
                    PlayerStats newStats = new PlayerStats();
                    newStats.setMatch(matchRepository.findById(matchId).orElseThrow());
                    newStats.setPlayer(playerRepository.findById(playerId).orElseThrow());
                    return newStats;
                });
    }

    public List<PlayerStats> getAllPlayerStats() {
        return playerStatsRepository.findAll();
    }

    public List<PlayerStats> getPlayerStatsByMatchId(Long matchId) {
        return playerStatsRepository.findByMatchId(matchId);
    }

    public void recordPoint(Long matchId, Long playerId) {
        PlayerStats stats = findOrCreateStats(matchId, playerId);
        stats.setPoint(stats.getPoint() + 1);
        playerStatsRepository.save(stats);
    }

    public void addAssist(Long matchId, Long playerId) {
        PlayerStats stats = findOrCreateStats(matchId, playerId);
        stats.setAssist(stats.getAssist() + 1);
        playerStatsRepository.save(stats);
    }

    public void recordError(Long matchId, Long playerId) {
        PlayerStats stats = findOrCreateStats(matchId, playerId);
        stats.setError(stats.getError() + 1);
        playerStatsRepository.save(stats);
    }

    public void recordAttack(Long matchId, Long playerId) {
        PlayerStats stats = findOrCreateStats(matchId, playerId);
        stats.setAttack(stats.getAttack() + 1);
        playerStatsRepository.save(stats);
    }

    public void recordBlock(Long matchId, Long playerId) {
        PlayerStats stats = findOrCreateStats(matchId, playerId);
        stats.setBlock(stats.getBlock() + 1);
        playerStatsRepository.save(stats);
    }

    public void recordServe(Long matchId, Long playerId) {
        PlayerStats stats = findOrCreateStats(matchId, playerId);
        stats.setServe(stats.getServe() + 1);
        playerStatsRepository.save(stats);
    }

    public void recordReception(Long matchId, Long playerId) {
        PlayerStats stats = findOrCreateStats(matchId, playerId);
        stats.setReception(stats.getReception() + 1);
        playerStatsRepository.save(stats);
    }
}
