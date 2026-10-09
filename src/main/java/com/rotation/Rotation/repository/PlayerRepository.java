package com.rotation.Rotation.repository;

import com.rotation.Rotation.entity.Player;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlayerRepository extends JpaRepository<Player, Long> {
    
    // Belirli bir takımın id'sine göre tüm oyuncularını getirmek için özel sorgu
    List<Player> findByTeamId(Long teamId);
}
