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
            }
            
            if rightSideParamsAreVisible == true {
                ParameterView(document.core)
                    .frame(minWidth: rightPanelWidth, idealWidth: rightPanelWidth, maxWidth: rightPanelWidth)
                    .layoutPriority(0)
                    .animation(.easeInOut)
            }
        }
        
        .toolbar {
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
