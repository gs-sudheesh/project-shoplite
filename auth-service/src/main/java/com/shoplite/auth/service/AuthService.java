package com.shoplite.auth.service;

import com.shoplite.auth.dto.AuthResponse;
import com.shoplite.auth.dto.LoginRequest;
import com.shoplite.auth.dto.RegisterRequest;
import com.shoplite.auth.domain.User;
import com.shoplite.auth.repo.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;


    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public AuthResponse login(LoginRequest request) {
        throw new UnsupportedOperationException(
                "Login is handled by Auth0. Obtain tokens via Auth0 Universal Login.");
    }

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.findByEmail(request.email()).isPresent()) {
            throw new RuntimeException("User already exists");
        }

        User user = new User();
        user.setName(request.name());
        user.setEmail(request.email());
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setRole("USER");

        User savedUser = userRepository.save(user);
        return new AuthResponse(null, "Bearer", 0L, savedUser.getId().toString(),
                savedUser.getEmail(), savedUser.getName());
    }

    public AuthResponse validateToken(String token) {
        throw new UnsupportedOperationException("Token validation is handled by resource server.");
    }
}
