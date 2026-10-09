package com.rotation.Rotation.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.rotation.Rotation.entity.Honours;
import com.rotation.Rotation.service.HonoursService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/honours")
@RequiredArgsConstructor
public class HonoursController {
    private final HonoursService honoursService;

    @GetMapping("/player/{playerId}")
    public List<Honours> getByPlayerId(@PathVariable Long playerId) {
        return honoursService.getByPlayerId(playerId);
    }

    @GetMapping("/team/{teamId}")
    public List<Honours> getByTeamId(@PathVariable Long teamId) {
        return honoursService.getByTeamId(teamId);
    }

    @GetMapping("/all")
    public List<Honours> getAllHonours() {
        return honoursService.getAllHonours();
    }

    @PostMapping
    public Honours addHonours(@RequestBody Honours honours) {
        return honoursService.addHonours(honours);
    }

    @PutMapping
    public Honours updateHonours(@RequestBody Honours honours) {
        return honoursService.updateHonours(honours);
    }

    @DeleteMapping("/{id}")
    public void deleteHonours(@PathVariable Long id) {
        honoursService.deleteHonours(id);
    }

    @GetMapping("/{id}")
    public Honours getHonoursById(@PathVariable Long id) {
        return honoursService.getHonoursById(id);
    }

}
