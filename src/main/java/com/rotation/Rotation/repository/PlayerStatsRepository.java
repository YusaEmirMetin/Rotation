package com.rotation.Rotation.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.rotation.Rotation.entity.PlayerStats;

@Repository
public interface PlayerStatsRepository extends JpaRepository<PlayerStats, Long> {

    // MaçID ve OyuncuID ye göre PlayerStats bulur.
    // Optional döndürür çünkü her oyuncunun o maçta stats kaydı olmayabilir.
    Optional<PlayerStats> findByMatchIdAndPlayerId(Long matchId, Long playerId);

    List<PlayerStats> findByMatchId(Long matchId);
}
