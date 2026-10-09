package com.rotation.Rotation.controller;

import org.springframework.web.bind.annotation.RestController;

import com.rotation.Rotation.entity.Fixture;
import com.rotation.Rotation.service.FixtureService;

import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/fixtures")
public class FixtureController {
    private final FixtureService fixtureService;

    @GetMapping("/tournamentWeek/{tournamentWeek}")
    public List<Fixture> getFixturesByTournamentWeek(@PathVariable Integer tournamentWeek) {
        return fixtureService.getFixturesByTournamentWeek(tournamentWeek);
    }

    @GetMapping
    public List<Fixture> getAllFixtures() {
        return fixtureService.findAll();
    }

    @GetMapping("/tournamentWeek/{tournamentWeek}/matchDay/{matchDay}")
    public List<Fixture> getFixturesByTournamentWeekAndMatchDay(@PathVariable Integer tournamentWeek,
            @PathVariable Integer matchDay) {
        return fixtureService.getFixturesByTournamentWeekAndMatchDay(tournamentWeek, matchDay);
    }

}
