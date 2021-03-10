//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 10/3/21.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: RaytracedDocument

    var body: some View {
        MetalView(document.core, .Main)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(RaytracedDocument()))
    }
}
