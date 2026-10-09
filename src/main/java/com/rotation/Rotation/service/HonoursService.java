package com.rotation.Rotation.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.rotation.Rotation.entity.Honours;
import com.rotation.Rotation.repository.HonoursRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class HonoursService {
    private final HonoursRepository honoursRepository;

    public List<Honours> getByPlayerId(Long playerId) {
        return honoursRepository.findByPlayerId(playerId);
    }

    public List<Honours> getByTeamId(Long teamId) {
        return honoursRepository.findByTeamId(teamId);
    }

    public List<Honours> getAllHonours() {
        return honoursRepository.findAll();
    }

    public Honours addHonours(Honours honours) {
        return honoursRepository.save(honours);
    }

    public Honours updateHonours(Honours honours) {
        return honoursRepository.save(honours);
    }

    public void deleteHonours(Long id) {
        honoursRepository.deleteById(id);
    }

    public Honours getHonoursById(Long id) {
        return honoursRepository.findById(id).orElse(null);
    }
}
