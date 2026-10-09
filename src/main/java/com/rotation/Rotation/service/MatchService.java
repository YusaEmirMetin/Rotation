package com.rotation.Rotation.service;

import com.rotation.Rotation.dto.ScoreUpdateDto;
import com.rotation.Rotation.entity.Match;
import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.entity.Tournament;
import com.rotation.Rotation.repository.FixtureRepository;
import com.rotation.Rotation.repository.MatchRepository;
import com.rotation.Rotation.repository.TeamRepository;
import com.rotation.Rotation.repository.TournamentStandingRepository;
import com.rotation.Rotation.entity.Fixture;
import com.rotation.Rotation.entity.TournamentStanding;

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
    private final TournamentStandingRepository tournamentStandingRepository;
    private final FixtureRepository fixtureRepository;

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

    public Optional<Match> getMatchById(Long id) {
        return matchRepository.findById(id);
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
        if (!"FINISHED".equals(match.getStatus()) && (match.getTeam1Sets() == 3 || match.getTeam2Sets() == 3)) {
            matchRepository.save(match);
            return finishMatch(match.getId());
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
        
        if ("FINISHED".equals(match.getStatus())) {
            return match; // Zaten bitmişse tekrar hesaplama
        }
        
        match.setStatus("FINISHED");
        Match saved = matchRepository.save(match);
        broadcast(saved);

        // Turnuva maçıysa puan durumunu ve fikstürü güncelle
        if (match.getTournament() != null) {
            updateStandingsForMatch(match);
            
            // Eğer bu maç bir fikstüre aitse, fikstürü de güncelle
            fixtureRepository.findAll().stream()
                .filter(f -> f.getMatchId() != null && f.getMatchId().equals(matchId))
                .findFirst()
                .ifPresent(f -> {
                    f.setStatus("FINISHED");
                    f.setHomeTeamScore(match.getTeam1Sets());
                    f.setAwayTeamScore(match.getTeam2Sets());
                    fixtureRepository.save(f);
                });
        }

        return saved;
    }

    private void updateStandingsForMatch(Match match) {
        Tournament tour = match.getTournament();
        Long tourId = tour.getId();
        
        // Takım 1 Puan Durumunu Getir veya Oluştur
        Team team1 = teamRepository.findByName(match.getTeam1Name())
                .orElseThrow(() -> new IllegalArgumentException("Team 1 not found"));
        TournamentStanding st1 = tournamentStandingRepository.findByTournamentIdAndTeamName(tourId, match.getTeam1Name())
                .orElseGet(() -> TournamentStanding.builder().tournament(tour).team(team1).build());

        st1.setPlayedMatches(st1.getPlayedMatches() + 1);
        st1.setWonSets(st1.getWonSets() + match.getTeam1Sets());
        st1.setLostSets(st1.getLostSets() + match.getTeam2Sets());
        st1.setSetDifference(st1.getWonSets() - st1.getLostSets());
        
        if (match.getTeam1Sets() > match.getTeam2Sets()) {
            st1.setWins(st1.getWins() + 1);
            if (match.getTeam2Sets() <= 1) st1.setPoints(st1.getPoints() + 3);
            else st1.setPoints(st1.getPoints() + 2);
        } else {
            st1.setLosses(st1.getLosses() + 1);
            if (match.getTeam1Sets() == 2) st1.setPoints(st1.getPoints() + 1);
        }
        tournamentStandingRepository.save(st1);

        // Takım 2 Puan Durumunu Getir veya Oluştur
        Team team2 = teamRepository.findByName(match.getTeam2Name())
                .orElseThrow(() -> new IllegalArgumentException("Team 2 not found"));
        TournamentStanding st2 = tournamentStandingRepository.findByTournamentIdAndTeamName(tourId, match.getTeam2Name())
                .orElseGet(() -> TournamentStanding.builder().tournament(tour).team(team2).build());

        st2.setPlayedMatches(st2.getPlayedMatches() + 1);
        st2.setWonSets(st2.getWonSets() + match.getTeam2Sets());
        st2.setLostSets(st2.getLostSets() + match.getTeam1Sets());
        st2.setSetDifference(st2.getWonSets() - st2.getLostSets());
        
        if (match.getTeam2Sets() > match.getTeam1Sets()) {
            st2.setWins(st2.getWins() + 1);
            if (match.getTeam1Sets() <= 1) st2.setPoints(st2.getPoints() + 3);
            else st2.setPoints(st2.getPoints() + 2);
        } else {
            st2.setLosses(st2.getLosses() + 1);
            if (match.getTeam2Sets() == 2) st2.setPoints(st2.getPoints() + 1);
        }
        tournamentStandingRepository.save(st2);
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
