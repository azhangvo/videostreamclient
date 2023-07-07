//
//  ContentView.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 2/4/23.
//

import SwiftUI
import SwiftyZeroMQ5

class ZMQObservable: ObservableObject {
    @Published var context: SwiftyZeroMQ.Context?
    @Published var socket: SwiftyZeroMQ.Socket?
    
    init() {
        do {
            let zmqcontext = try SwiftyZeroMQ.Context()
            context = zmqcontext
            try socket = zmqcontext.socket(.reply)
        } catch {
            print("Context creation failure: \(error)")
        }
    }
}

struct ContentView: View {
    @ObservedObject private var zmqObservable = ZMQObservable()
    
    var body: some View {
        NavigationView {
            ZStack {
                HostedViewController().ignoresSafeArea()
                VStack(alignment: .leading) {
                    NavigationLink(destination: SettingView()) {
                        Text("Settings")
                            .foregroundColor(Color.blue)
                            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topTrailing)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, DataController().container.viewContext)
    }
}
