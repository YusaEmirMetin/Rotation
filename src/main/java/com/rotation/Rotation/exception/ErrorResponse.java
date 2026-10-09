package com.rotation.Rotation.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
public class ErrorResponse {
    private LocalDateTime timestamp; // Hatanın olduğu an
    private int status;              // HTTP Kodu (Örn: 400, 404, 500)
    private String error;            // Hatanın kısa adı
    private String message;          // Kullanıcıya göstereceğimiz mesaj
    private String path;             // Hatanın alındığı adres (Örn: /api/teams)
}
