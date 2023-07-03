//
//  TCPClient.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 2/4/23.
//

import Foundation
import Network

class TCPClient {
    init() {
        print("Establishing connection")
        let connection = NWConnection(to: .hostPort(host: "167.99.144.52", port: 9998), using: .tcp);
        
        while(connection.state != .ready) {
            print("Waiting...")
        }
        
        print("Ready state")
        
        print("Sending data...")
        
        connection.send(content: .init(count: 100), completion: .idempotent)
        
        print("Data sent")
    }
}
