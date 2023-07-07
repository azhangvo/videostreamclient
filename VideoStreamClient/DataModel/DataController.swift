//
//  DataController.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 7/6/23.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "ServerModel")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func save(context: NSManagedObjectContext) {
        do {
            try context.save()
            print("Data saved")
        } catch {
            print("Data could not be saved")
        }
    }
    
    func addServer(context: NSManagedObjectContext) {
        let server = Server(context: context)
        server.ip = ""
        server.port = 8001
        
        save(context: context)
    }
    
    func editServer(server: Server, ip: String, port: Int32, context: NSManagedObjectContext) {
        server.ip = ip
        server.port = port
        
        save(context: context)
    }
}
