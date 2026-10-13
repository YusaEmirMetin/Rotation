package com.rotation.Rotation.repository;

import com.rotation.Rotation.entity.Referee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RefereeRepository extends JpaRepository<Referee, Long> {

}
