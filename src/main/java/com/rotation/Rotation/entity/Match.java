package com.rotation.Rotation.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "matches")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "team1_name", nullable = false)
    private String team1Name;

    @Column(name = "team2_name", nullable = false)
    private String team2Name;

    @Column(name = "team1_score", nullable = false)
    @Builder.Default
    private Integer team1Score = 0;

    @Column(name = "team2_score", nullable = false)
    @Builder.Default
    private Integer team2Score = 0;

    @Column(name = "team1_sets", nullable = false)
    @Builder.Default
    private Integer team1Sets = 0;

    @Column(name = "team2_sets", nullable = false)
    @Builder.Default
    private Integer team2Sets = 0;

    // ACTIVE veya FINISHED
    @Column(nullable = false)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    @ManyToOne
    @JoinColumn(name = "tournament_id")
    private Tournament tournament;
}
