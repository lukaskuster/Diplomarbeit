//
//  ICEExchange.swift
//  SIMplePhoneKit
//
//  Created by Lukas Kuster on 18.10.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import SocketIO

public class ICEExchange {
    let manager = SocketManager(socketURL: URL(string: "http://172.20.10.5:10001")!, config: [.log(false)])
    
    public func tryoutSocket() {
        let socket = self.manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            
            socket.emit("authenticate", [
                "username": "quentin@wendegass.com",
                "password": "test123"])
        }
        
        socket.connect()
        
        
        socket.on("authenticated") { (response, emitter) in
            print(response)
            print(emitter)
        }
        
        socket.on("start") { (response, emitter) in
            socket.emit("offer", "irgend ein string")
        }
        
        socket.on("answer") { (response, emitter) in
            print(response)
            socket.disconnect()
        }
        
        socket.on("offer") { (response, emitter) in
            print(response)
            socket.emit("answer", "irgend ein zweiter string")
            socket.disconnect()
        }
        
        
        
    }
}
