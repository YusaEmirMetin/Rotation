package com.rotation.Rotation.repository;

import com.rotation.Rotation.entity.Team;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TeamRepository extends JpaRepository<Team, Long> {

    // Spring Data JPA metodun isminden otomatik olarak SQL sorgusu üretir.
    // Karşılığı: SELECT * FROM teams WHERE name = ?
    Optional<Team> findByName(String name);

    // İleride takımları kuruluş yılına göre getirmek istersek:
    // List<Team> findAllByEstablishedYear(Integer year);
}
