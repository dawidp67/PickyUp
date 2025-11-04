//
//  MainTabView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            GameListView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt")
                }
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

