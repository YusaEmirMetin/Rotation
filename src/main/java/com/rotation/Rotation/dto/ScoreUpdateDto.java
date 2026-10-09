package com.rotation.Rotation.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ScoreUpdateDto {
    private Long matchId;
    private String team1Name;
    private String team2Name;
    private Integer team1Score;
    private Integer team2Score;
    private String status;
    private Integer team1Sets;
    private Integer team2Sets;
}
