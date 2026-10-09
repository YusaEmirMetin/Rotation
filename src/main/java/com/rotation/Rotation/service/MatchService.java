package com.rotation.Rotation.service;

import com.rotation.Rotation.dto.ScoreUpdateDto;
import com.rotation.Rotation.entity.Match;
import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.repository.MatchRepository;
import com.rotation.Rotation.repository.TeamRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class MatchService {

    private final MatchRepository matchRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final TeamRepository teamRepository;
    private final TournamentService tournamentService;

    // Yeni maç başlat
    @Transactional
    public Match startMatch(String team1Name, String team2Name) {
        Match match = Match.builder()
                .team1Name(team1Name)
                .team2Name(team2Name)
                .team1Score(0)
                .team2Score(0)
                .status("ACTIVE")
                .build();
        Match saved = matchRepository.save(match);
        broadcast(saved);
        return saved;
    }

    // Aktif maçı getir
    public Optional<Match> getActiveMatch() {
        return matchRepository.findFirstByStatusOrderByCreatedAtDesc("ACTIVE");
    }

    // Skor güncelle: team = 1 veya 2, delta = +1 veya -1
    @Transactional
    public Match updateScore(Long matchId, int team, int delta) {
        Match match = matchRepository.findById(matchId)
                .orElseThrow(() -> new IllegalArgumentException("Maç bulunamadı: " + matchId));

        if (team == 1) {
            int newScore = Math.max(0, match.getTeam1Score() + delta);
            match.setTeam1Score(newScore);
        } else if (team == 2) {
            int newScore = Math.max(0, match.getTeam2Score() + delta);
            match.setTeam2Score(newScore);
        }

        // Set kazanma puanını belirle (5. set 15'te biter, diğerleri 25'te)
        int totalSetsPlayed = match.getTeam1Sets() + match.getTeam2Sets();
        int targetScore = (totalSetsPlayed == 4) ? 15 : 25;

        // Kim kazandı kontrol et (Hedefe ulaşılmış mı ve fark en az 2 mi?)
        if (match.getTeam1Score() >= targetScore && (match.getTeam1Score() - match.getTeam2Score()) >= 2) {
            // Takım 1 seti aldı
            match.setTeam1Sets(match.getTeam1Sets() + 1);
            match.setTeam1Score(0);
            match.setTeam2Score(0);
        } else if (match.getTeam2Score() >= targetScore && (match.getTeam2Score() - match.getTeam1Score()) >= 2) {
            // Takım 2 seti aldı
            match.setTeam2Sets(match.getTeam2Sets() + 1);
            match.setTeam1Score(0);
            match.setTeam2Score(0);
        }

        // Maç bitti mi kontrol et (İlk 3 set alan kazanır)
        if (match.getTeam1Sets() == 3 || match.getTeam2Sets() == 3) {
            match.setStatus("FINISHED");
        }

        Match saved = matchRepository.save(match);
        // Tüm bağlı istemcilere yeni skoru gönder
        broadcast(saved);
        return saved;
    }

    // Maçı bitir
    @Transactional
    public Match finishMatch(Long matchId) {
        Match match = matchRepository.findById(matchId)
                .orElseThrow(() -> new IllegalArgumentException("Maç bulunamadı: " + matchId));
        match.setStatus("FINISHED");
        Match saved = matchRepository.save(match);
        broadcast(saved);
        return saved;
    }

    @Transactional
    public Match startMatchFromTeams(Long team1Id, Long team2Id) {
        // Takımları ID ile bul, bulamazsa hata fırlat
        Team team1 = teamRepository.findById(team1Id)
                .orElseThrow(() -> new IllegalArgumentException("Takım bulunamadı: " + team1Id));
        Team team2 = teamRepository.findById(team2Id)
                .orElseThrow(() -> new IllegalArgumentException("Takım bulunamadı: " + team2Id));

        // Adları alıp mevcut startMatch metodunu çağır
        return startMatch(team1.getName(), team2.getName());
    }

    // Sadece Bitmiş Maçları getir
    public List<Match> getFinishedMatches() {
        return matchRepository.findByStatusOrderByCreatedAtDesc("FINISHED");
    }

    // Maç Sil
    @Transactional
    public void deleteMatch(Long matchId) {
        matchRepository.deleteById(matchId);
    }

    // WebSocket üzerinden /topic/score kanalına broadcast
    private void broadcast(Match match) {
        ScoreUpdateDto dto = ScoreUpdateDto.builder()
                .matchId(match.getId())
                .team1Name(match.getTeam1Name())
                .team2Name(match.getTeam2Name())
                .team1Score(match.getTeam1Score())
                .team2Score(match.getTeam2Score())
                .team1Sets(match.getTeam1Sets())
                .team2Sets(match.getTeam2Sets())
                .status(match.getStatus())
                .build();
        messagingTemplate.convertAndSend("/topic/score", dto);
    }

    public Match createMatchFromTournament(Long tournamentId) {
        Tournament tournament = tournamentService.getTournamentById(tournamentId);
        
        String t1Name = "Team A";
        String t2Name = "Team B";
        
        if (tournament.getTeams() != null && tournament.getTeams().size() >= 2) {
            t1Name = tournament.getTeams().get(0).getName();
            t2Name = tournament.getTeams().get(1).getName();
        }

        Match match = startMatch(t1Name, t2Name);
        match.setTournament(tournament);
        return matchRepository.save(match);
    }
}
