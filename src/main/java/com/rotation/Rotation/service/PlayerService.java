package com.rotation.Rotation.service;

import com.rotation.Rotation.entity.Player;
import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.repository.PlayerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PlayerService {

    private final PlayerRepository playerRepository;
    private final TeamService teamService; // Takımı bulmak için TeamService'i çağırıyoruz

    // 1. ID'si verilen takıma yeni bir oyuncu ekler
    public Player addPlayerToTeam(Long teamId, Player player) {
        // Önce takımı bul (Eğer takım yoksa TeamService zaten otomatik hata fırlatacak)
        Team team = teamService.getTeamById(teamId);

        // Oyuncuya "sen bu takımdasın" bilgisini ver
        player.setTeam(team);

        // İleride buraya iş kuralları eklenebilir: (Örn: Bir takımda aynı forma
        // numarası olamaz)

        // Veritabanına kaydet
        return playerRepository.save(player);
    }

    // 2. Bir takımın tüm oyuncularını listeler
    public List<Player> getPlayersByTeamId(Long teamId) {
        // Takımın var olup olmadığını kontrol edelim
        teamService.getTeamById(teamId);

        // O takıma ait oyuncuları getir
        return playerRepository.findByTeamId(teamId);
    }

    // 3. Ligdeki tüm oyuncuları getir
    public List<Player> getAllPlayers() {
        return playerRepository.findAll();
    }

    // 4.Oyuncu Sil
    public void deletePlayer(Long playerId) {
        playerRepository.deleteById(playerId);
    }

    // 5.Oyuncu Değeri
    public double getPlayerValue(Long playerId) {
        return playerRepository.findById(playerId).get().getPlayerValue();
    }

    // 6.Oyuncuyu Bul ve Getir
    public Player getPlayerById(Long playerId) {
        return playerRepository.findById(playerId).get();
    }
}
