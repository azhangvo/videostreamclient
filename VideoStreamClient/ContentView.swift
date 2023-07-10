//
//  ContentView.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 2/4/23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("reset_observer") private var reset_observer: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                HostedViewController().ignoresSafeArea()
                VStack(alignment: .leading) {
                    HStack {
                        Button("Reset") {
                            UserDefaults.standard.set(!reset_observer, forKey: "reset_observer")
                        }
                        .padding(.all)
                        Spacer()
                        NavigationLink(destination: SettingView()) {
                            Text("Settings")
                                .foregroundColor(Color.blue)
                                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
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
