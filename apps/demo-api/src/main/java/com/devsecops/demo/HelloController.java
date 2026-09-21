package com.devsecops.demo;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @Value("${app.message:Hello from DevSecOps demo-api}")
    private String message;

    @GetMapping("/api/hello")
    public Map<String, String> hello() {
        return Map.of(
                "message", message,
                "service", "demo-api",
                "status", "ok"
        );
    }
}
