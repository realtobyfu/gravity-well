//
//  ContentView.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        GameViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

struct GameViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GravityWellGameViewController {
        return GravityWellGameViewController()
    }

    func updateUIViewController(_ uiViewController: GravityWellGameViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    ContentView()
}