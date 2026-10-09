package com.rotation.Rotation.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor

public class StartMatchRequest {
    private Long team1Id;
    private Long team2Id;
}
