package com.rotation.Rotation.controller;

import com.rotation.Rotation.entity.Team;
import com.rotation.Rotation.service.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teams")
@RequiredArgsConstructor
public class TeamController {

    private final TeamService teamService;

    // POST isteği ile "/api/teams" adresine gelen veriyi yakalar ve yeni takım oluşturur
    @PostMapping
    public ResponseEntity<Team> createTeam(@RequestBody Team team) {
        Team createdTeam = teamService.createTeam(team);
        return new ResponseEntity<>(createdTeam, HttpStatus.CREATED); // 201 Created döner
    }

    // GET isteği ile "/api/teams" adresinden tüm takımları liste olarak döner
    @GetMapping
    public ResponseEntity<List<Team>> getAllTeams() {
        List<Team> teams = teamService.getAllTeams();
        return ResponseEntity.ok(teams); // 200 OK döner
    }

    // GET isteği ile "/api/teams/1" adresinden ID'si 1 olan takımı döner
    @GetMapping("/{id}")
    public ResponseEntity<Team> getTeamById(@PathVariable Long id) {
        Team team = teamService.getTeamById(id);
        return ResponseEntity.ok(team); // 200 OK döner
    }
}
