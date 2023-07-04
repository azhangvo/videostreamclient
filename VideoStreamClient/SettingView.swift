//
//  SettingView.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 7/3/23.
//

import SwiftUI

struct SettingView: View {
    @State var ipaddress: String = ""
    @State var port: String = ""
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .trailing) {
                    Text("IP Address")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize()
                    Text("Port")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize()
                }
                Divider()
                VStack(alignment: .leading) {
                    TextField("IP Address", text: $ipaddress)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize()
                    TextField("Port", text: $port)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize()
                }
            }
            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            Button("Update Settings") {
                // Update Settings
                // TODO: Add validation, checking, and toast w/ status update
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0,
               maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(Text("Settings"))
        
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
