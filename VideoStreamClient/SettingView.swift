//
//  SettingView.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 7/3/23.
//

import SwiftUI
import SwiftyZeroMQ5

struct SettingView: View {
    @Environment(\.managedObjectContext) var managedObjContext
    @FetchRequest(sortDescriptors: []) var servers: FetchedResults<Server>
    
    @AppStorage("ipaddress") private var storageIpAddress: String = ""
    @AppStorage("port") private var storagePort: Int = 8001
    
    @State private var ipaddress: String = ""
    @State private var port: String = "8001"
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .trailing) {
                    Text("IP Address")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Port")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Divider()
                VStack(alignment: .leading) {
                    TextField("IP Address", text: $ipaddress)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize(horizontal: false, vertical: true)
                    TextField("Port", text: $port)
                        .frame(height: 28)
                        .padding(/*@START_MENU_TOKEN@*/.all, 6.0/*@END_MENU_TOKEN@*/)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            Button("Update Settings") {
                // Update Settings
                // TODO: Add toast w/ status update
                
                let urlOrIpRegex = /^(http(s?):\/\/)?(((www\.)?+[a-zA-Z0-9\.\-\_]+(\.[a-zA-Z]{2,3})+)|(\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b))(\/[a-zA-Z0-9\_\-\s\.\/\?\%\#\&\=]*)?$/
                
                if(!ipaddress.contains(urlOrIpRegex)) {
                    print("Invalid IP (Must be either URL or IP Address)")
                    return
                }
                
                guard let portValue = Int32(port) else {
                    print("Invalid port (Must be an integer between 0-65535)")
                    return
                }
                
                if(portValue < 0 || portValue > 65535) {
                    print("Invalid port (Must be an integer between 0-65535)")
                    return
                }
                
//                DataController().editServer(server: servers.first!, ip: ipaddress, port: portValue, context: managedObjContext)
                UserDefaults.standard.set(ipaddress, forKey: "ipaddress")
                UserDefaults.standard.set(portValue, forKey: "port")
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0,
               maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(Text("Settings"))
        .onAppear {
//            if(servers.count == 0) {
//                DataController().addServer(context: managedObjContext)
//                port = "8001"
//            } else {
//                ipaddress = servers.first?.ip ?? ""
//                port = String(Int(servers.first?.port ?? 8001))
//            }
            ipaddress = storageIpAddress
            port = String(storagePort)
        }
        
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
