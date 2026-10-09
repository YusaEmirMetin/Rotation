package com.rotation.Rotation.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.rotation.Rotation.entity.Honours;

@Repository
public interface HonoursRepository extends JpaRepository<Honours, Long> {
    List<Honours> findByPlayerId(Long playerId);

    List<Honours> findByTeamId(Long teamId);
}
