//
//  VideoStreamClientApp.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 2/4/23.
//

import SwiftUI

@main
struct VideoStreamClientApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
