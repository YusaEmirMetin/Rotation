package com.rotation.Rotation.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Sunucunun mesaj gönderdiği prefix: /topic/...
        config.enableSimpleBroker("/topic");
        // İstemcinin mesaj gönderdiği prefix: /app/...
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Flutter WebSocket bağlantı noktası: ws://host:8080/ws
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");
    }
}
