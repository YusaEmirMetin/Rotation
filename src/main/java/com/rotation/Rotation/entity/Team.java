package com.rotation.Rotation.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import com.fasterxml.jackson.annotation.JsonIgnore;

@Entity
@Table(name = "teams")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Team {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(name = "coach_name")
    private String coachName;

    @Column(name = "established_year")
    private Integer establishedYear;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // One team has MANY players. (Tekten çoğa ilişki)
    // mappedBy: İlişkinin sahibi Player sınıfındaki 'team' değişkenidir.
    // cascade = CascadeType.ALL: Takım silinirse, o takımdaki tüm oyuncular da veritabanından silinsin.
    // orphanRemoval = true: Takım listesinden çıkarılan oyuncu veritabanından silinsin.
    @JsonIgnore
    @OneToMany(mappedBy = "team", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<Player> players = new ArrayList<>();

    // Veritabanına ilk kez kaydedilirken otomatik olarak o anın tarihini atar
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
