package com.rotation.Rotation.entity;

import java.time.LocalDate;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import com.rotation.Rotation.entity.enums.TournamentStatus;

@Getter
@Setter
@Table(name = "tournaments")
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Tournament {
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Id
    private Long id;

    @Column(name = "tournament_name", nullable = false)
    private String tournamentName;

    @Column(name = "tournament_type", nullable = false)
    private String tournamentType;

    @Column(name = "tournament_start_date", nullable = false)
    private LocalDate tournamentStartDate;

    @Column(name = "tournament_end_date", nullable = false)
    private LocalDate tournamentEndDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "tournament_status", nullable = false)
    private TournamentStatus tournamentStatus;

    @ManyToMany
    @JoinTable(name = "tournament_teams", joinColumns = @JoinColumn(name = "tournament_id", referencedColumnName = "id"), inverseJoinColumns = @JoinColumn(name = "team_id", referencedColumnName = "id"))
    private List<Team> teams = new java.util.ArrayList<>();
}
