package com.rotation.Rotation.service;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import java.util.List;
import com.rotation.Rotation.entity.Fixture;
import com.rotation.Rotation.repository.FixtureRepository;
import com.rotation.Rotation.repository.TournamentRepository;
import com.rotation.Rotation.repository.TournamentStandingRepository;

@Service
@RequiredArgsConstructor
public class FixtureService {
    private final FixtureRepository fixtureRepository;
    private final TournamentRepository tournamentRepository;
    private final TournamentStandingRepository tournamentStandingRepository;

    public List<Fixture> getFixturesByTournamentWeek(Integer tournamentWeek) {
        return fixtureRepository.findByTournamentWeek(tournamentWeek);
    }

    public List<Fixture> findAll() {
        return fixtureRepository.findAll();
    }

    public List<Fixture> getFixturesByTournamentWeekAndMatchDay(Integer tournamentWeek, Integer matchDay) {
        return fixtureRepository.findByTournamentWeekAndMatchDay(tournamentWeek, matchDay);
    }
}