//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 10/3/21.
//

import SwiftUI

#if os(macOS)
let leftPanelWidth                      : CGFloat = 180
#else
let leftPanelWidth                      : CGFloat = 230
#endif

#if os(macOS)
let rightPanelWidth                     : CGFloat = 180
#else
let rightPanelWidth                     : CGFloat = 230
#endif

struct ContentView: View {
    
    @Binding var document: RaytracedDocument

    @State private var rightSideParamsAreVisible        : Bool = true

    var body: some View {
        
        HStack {

            NavigationView {
                    
                LeftPanelView(document.core)
                    .frame(minWidth: leftPanelWidth, idealWidth: leftPanelWidth, maxWidth: leftPanelWidth)
                    .layoutPriority(0)
                    .animation(.easeInOut)
                MetalView(document.core, .Main)
                    .animation(.easeInOut)
            }
            
            if rightSideParamsAreVisible == true {
                ParameterView(document.core)
                    .frame(minWidth: rightPanelWidth, idealWidth: rightPanelWidth, maxWidth: rightPanelWidth)
                    .layoutPriority(0)
                    .animation(.easeInOut)
            }
        }
        
        .toolbar {
            
            // Core Controls
            Button(action: {
                let box = document.core.assetFolder.addBox(name: "New Cube")
                document.core.assetFolder.setCurrent(box)
                document.core.renderer.restart()
                document.core.modelChanged.send()
            })
            {
                Label("Add", systemImage: "cube")
            }
            
            Button(action: {
                let light = document.core.assetFolder.addLight(name: "New Light")
                document.core.assetFolder.setCurrent(light)
                document.core.renderer.restart()
                document.core.modelChanged.send()
            })
            {
                Label("Add", systemImage: "lightbulb")
            }
            
            Divider()
                .padding(.horizontal, 2)
                .opacity(0)
            
            // Toggle the Right sidebar
            Button(action: { rightSideParamsAreVisible.toggle() }, label: {
                Image(systemName: "sidebar.right")
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(RaytracedDocument()))
    }
}
