//
//  ContentView.swift
//  HSharePlay
//
//  Created by huangqun on 2021/11/2.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: PlayColorView()) {
                Text("换色")
                }
                
                Spacer()
                    .frame(height: 50)
                
                NavigationLink(destination: MovieView()) {
                    Text("看视频")
                }
                
                Spacer()
                    .frame(height: 50)
                
                NavigationLink(destination: EmptyView()) {
                    Text("听音乐")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
