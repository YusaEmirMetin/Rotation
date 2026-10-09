package com.rotation.Rotation.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // Tüm uç noktalara (/**) her türlü kaynaktan erişime izin ver
        registry.addMapping("/**")
                .allowedOrigins("*") // Chrome üzerinden gelen (farklı port) istekleri kabul et
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}
