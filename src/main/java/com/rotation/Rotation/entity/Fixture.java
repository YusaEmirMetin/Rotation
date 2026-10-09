package com.rotation.Rotation.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.Id;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;

@Entity
@Getter
@Setter
@Table(name = "fixtures")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Fixture {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "tournament_id", nullable = false)
    private Tournament tournament;

    private Integer tournamentWeek;

    private Integer matchDay;

    private Integer matchOrder;

    private Long homeTeamId;

    private Long awayTeamId;

    private Integer homeTeamScore;

    private Integer awayTeamScore;

    @Builder.Default
    private String status = "SCHEDULED"; // SCHEDULED, ACTIVE, FINISHED

    private Long matchId; // Link to the actual live Match object if started
}
