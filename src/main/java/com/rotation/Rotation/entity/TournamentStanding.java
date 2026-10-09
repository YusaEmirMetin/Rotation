package com.rotation.Rotation.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@Table(name = "tournament_standings")
@NoArgsConstructor
@AllArgsConstructor
@Builder

public class TournamentStanding {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "tournament_id", nullable = false)
    private Tournament tournament;

    @ManyToOne
    @JoinColumn(name = "team_id", nullable = false)
    private Team team;

    @Builder.Default
    private int playedMatches = 0;

    @Builder.Default
    private int wins = 0;

    @Builder.Default
    private int draws = 0;

    @Builder.Default
    private int losses = 0;

    @Builder.Default
    private int points = 0;

    @Builder.Default
    private int wonSets = 0;

    @Builder.Default
    private int lostSets = 0;

    @Builder.Default
    private int wonGames = 0;

    @Builder.Default
    private int lostGames = 0;

    @Builder.Default
    private int gameDifference = 0;

    @Builder.Default
    private int setDifference = 0;

}
