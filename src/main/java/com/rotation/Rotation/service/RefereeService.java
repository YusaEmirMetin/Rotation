package com.rotation.Rotation.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.rotation.Rotation.entity.Referee;
import com.rotation.Rotation.repository.RefereeRepository;

import lombok.RequiredArgsConstructor;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RefereeService {

    private final RefereeRepository refereeRepository;

    public Referee getRefereeById(Long id) {
        return refereeRepository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                "Referee not found with id: " + id));
    }

    public Referee createReferee(Referee referee) {
        return refereeRepository.save(referee);
    }

    public List<Referee> getAllReferees() {
        return refereeRepository.findAll();
    }

    public void deleteReferee(Long id) {
        if (!refereeRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Referee not found with id: " + id);
        }
        refereeRepository.deleteById(id);
    }

}
