//
//  H265UncompressedTexturesApp.swift
//  H265UncompressedTextures
//
//  Created by Max Thomas on 8/6/24.
//

import SwiftUI

@main
struct H265UncompressedTexturesApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    
                    VideoHandler.runTest()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
