//
//  ContentView.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 2/4/23.
//

import SwiftUI
import SwiftyZeroMQ5

struct ContentView: View {

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
