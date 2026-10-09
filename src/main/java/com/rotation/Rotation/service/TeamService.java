package com.rotation.Rotation.service;

import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.repository.TeamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class TeamService {

    private final TeamRepository teamRepository;

    // 1. Yeni bir takım oluşturur.
    // İş kuralı (Business Logic): Aynı isimde takım zaten varsa hata fırlat!
    public Team createTeam(Team team) {
        Optional<Team> existingTeam = teamRepository.findByName(team.getName());
        if (existingTeam.isPresent()) {
            throw new RuntimeException("Bu isimde bir takım zaten mevcut: " + team.getName());
        }
        
        // Eğer her şey yolundaysa, Repository aracılığıyla veritabanına kaydet.
        return teamRepository.save(team);
    }

    // 2. Veritabanındaki tüm takımları liste halinde döndürür.
    public List<Team> getAllTeams() {
        return teamRepository.findAll();
    }

    // 3. ID'ye göre takımı bulur.
    // İş kuralı: Eğer verilen ID'ye ait bir takım yoksa (null dönmek yerine) hata fırlat!
    public Team getTeamById(Long id) {
        return teamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Takım bulunamadı! ID: " + id));
    }
}
