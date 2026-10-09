package com.rotation.Rotation.repository;

import com.rotation.Rotation.entity.Match;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MatchRepository extends JpaRepository<Match, Long> {
    Optional<Match> findFirstByStatusOrderByCreatedAtDesc(String status);

    List<Match> findByStatusOrderByCreatedAtDesc(String status);
}
