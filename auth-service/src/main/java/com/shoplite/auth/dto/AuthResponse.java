package com.shoplite.auth.dto;

public record AuthResponse(String token, String type, Long expiresIn, String userId, String email,
        String name) {
}
