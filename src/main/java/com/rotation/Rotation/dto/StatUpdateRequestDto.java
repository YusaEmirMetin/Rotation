package com.rotation.Rotation.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StatUpdateRequestDto {
    private Long matchId;
    private List<StatItem> stats;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class StatItem {
        private Long playerId;
        private int point;
        private int assist;
        private int block;
        private int serve;
        private int reception;
        private int attack;
        private int error;
    }
}
