//
//  GlanceaApp.swift
//  Glancea
//
//  Created by Grant Megrabyan on 26/01/2026.
//

import SwiftUI

@main
struct GlanceaApp: App {
    var body: some Scene {
        MenuBarExtra("Glancea", systemImage: "checkmark.circle.fill") {
            MonitorsListView()
        }
//        WindowGroup {
//            ContentView()
//        }
    }
}
