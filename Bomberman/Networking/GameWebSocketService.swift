//
//  GameWebSocketService.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import Foundation

final class GameWebSocketService: NSObject {
    
    static let shared = GameWebSocketService()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private(set) var isConnected: Bool = false
    
    var onGameState: ((GameStateModel) -> Void)?
    var onAssignPlayerId: ((String) -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    
    override init() {
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration)
        super.init()
    }
    
    func connect() {
        guard webSocketTask == nil else { return }
        guard let url = NetworkConfig.webSocketURL else {
            print("Invalid WebSocket URL")
            return
        }
        
        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()
        isConnected = true
        
        listen()
    }
    
    func disconnect() {
        let reason = "Client closed connection".data(using: .utf8)
        webSocketTask?.cancel(with: .goingAway, reason: reason)
        webSocketTask = nil
        isConnected = false
        onDisconnected?(nil)
    }
    
    // MARK: - High-level API
    
    func sendJoin(name: String?, role: ClientRole) {
        let message = ClientMessage.join(name: name, role: role)
        send(message)
    }
    
    func sendReady() {
        let message = ClientMessage.ready()
        send(message)
    }
    
    func sendMove(dx: Int, dy: Int) {
        let message = ClientMessage.move(dx: dx, dy: dy)
        send(message)
    }
    
    func sendPlaceBomb() {
        let message = ClientMessage.placeBomb()
        send(message)
    }
    
    // MARK: - Low-level send / listen
    
    private func send(_ clientMessage: ClientMessage) {
        guard let task = webSocketTask else {
            print("WebSocket not connected")
            return
        }
        
        do {
            let data = try encoder.encode(clientMessage)
            if let text = String(data: data, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(text)
                task.send(message) { [weak self] error in
                    if let error = error {
                        print("Failed to send message: \(error)")
                        self?.handleDisconnect(error: error)
                    }
                }
            }
        } catch {
            print("Encoding error: \(error)")
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.handleDisconnect(error: error)
                
            case .success(let message):
                self.handle(message)
                self.listen()
            }
        }
    }
    
    private func handle(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleDataMessage(data)
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        handleDataMessage(data)
    }
    
    private func handleDataMessage(_ data: Data) {
        if let gameStateMessage = try? decoder.decode(GameStateMessage.self, from: data),
           gameStateMessage.type == "game_state" {
            let state = gameStateMessage.payload
            DispatchQueue.main.async { [weak self] in
                self?.onGameState?(state)
            }
            return
        }

        if let assignMessage = try? decoder.decode(AssignIdMessage.self, from: data),
           assignMessage.type == "assign_id" {
            let playerId = assignMessage.payload
            DispatchQueue.main.async { [weak self] in
                self?.onAssignPlayerId?(playerId)
            }
            return
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("Unknown message from server: \(jsonString)")
        }
    }
    
    private func handleDisconnect(error: Error?) {
        isConnected = false
        webSocketTask = nil
        DispatchQueue.main.async { [weak self] in
            self?.onDisconnected?(error)
        }
    }
}
