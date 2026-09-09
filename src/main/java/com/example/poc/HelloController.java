package com.example.poc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
@RestController
public class HelloController {
  @GetMapping("/")
  public String hello() { return "Hello from Jenkins to GitHub Actions POC"; }
  @GetMapping("/health")
  public String health() { return "UP"; }
}
