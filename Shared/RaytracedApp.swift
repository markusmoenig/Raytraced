//
//  RaytracedApp.swift
//  Shared
//
//  Created by Markus Moenig on 10/3/21.
//

import SwiftUI

@main
struct RaytracedApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: RaytracedDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
