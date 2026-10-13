package com.rotation.Rotation.controller;

import com.rotation.Rotation.entity.Referee;
import com.rotation.Rotation.service.RefereeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/referees")
@RequiredArgsConstructor
public class RefereeController {

    private final RefereeService refereeService;

    @PostMapping
    public ResponseEntity<Referee> createReferee(@Valid @RequestBody Referee referee) {
        Referee createdReferee = refereeService.createReferee(referee);
        return new ResponseEntity<>(createdReferee, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<Referee>> getAllReferees() {
        return ResponseEntity.ok(refereeService.getAllReferees());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Referee> getRefereeById(@PathVariable Long id) {
        Referee referee = refereeService.getRefereeById(id);
        return ResponseEntity.ok(referee);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteReferee(@PathVariable Long id) {
        refereeService.deleteReferee(id);
        return ResponseEntity.noContent().build();
    }
}