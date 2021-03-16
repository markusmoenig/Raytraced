//
//  Views.swift
//  Raytraced
//
//  Created by Markus Moenig on 15/3/21.
//

import SwiftUI

struct Float3ParamView: View {
    
    let core                                : Core
    
    var asset                               : Asset
    
    var valueName                           : String
    var displayName                         : String
    var updateView                          : Binding<Bool>
    
    @State var xValueText                   : String = ""
    @State var yValueText                   : String = ""
    @State var zValueText                   : String = ""

    init(core: Core, asset: Asset, valueName: String, displayName: String, updateView: Binding<Bool>)
    {
        self.core = core
        self.asset = asset
        self.valueName = valueName
        self.displayName = displayName
        self.updateView = updateView
        
        _xValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_x"]!))
        _yValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_y"]!))
        _zValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_z"]!))
            
        print("init", asset.name, _yValueText)
    }
    
    var body: some View {

        VStack(alignment: .leading) {
            Text(displayName)
            HStack {
                TextField(valueName, text: $xValueText, onEditingChanged: { (changed) in
                },
                onCommit: {
                    asset.values[valueName + "_x"] = Float(xValueText)
                    core.renderer.restart()
                } )
                //.padding(2)
                .border(Color.red)
                TextField(valueName, text: $yValueText, onEditingChanged: { (changed) in
                    asset.values[valueName + "_y"] = Float(yValueText)
                    core.renderer.restart()
                },
                onCommit: {
                } )
                //.padding(2)
                .border(Color.green)
                TextField(valueName, text: $zValueText, onEditingChanged: { (changed) in
                    asset.values[valueName + "_z"] = Float(zValueText)
                    core.renderer.restart()
                },
                onCommit: {
                } )
                //.padding(2)
                .border(Color.blue)
            }
        }
    }
}

struct ParameterView: View {
    
    let core                                : Core
    
    @State var asset                        : Asset? = nil
    
    @State var nameState                    : String = ""
    @State var updateView                   : Bool = false

    init(_ core: Core)
    {
        self.core = core
    }
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                
                if let currentAsset = asset {
                    Text("Name")
                    TextField(currentAsset.name, text: $nameState, onEditingChanged: { (changed) in
                        //option.raw = valueText
                    },
                    onCommit: {
                        //core.scriptProcessor.replaceOptionInLine(option, useRaw: true)
                        currentAsset.name = nameState
                        core.assetFolder.setCurrent()
                        core.assetFolder.setCurrent(asset)
                    } )
                    .padding(2)
                    
                    Float3ParamView(core: core, asset: currentAsset, valueName: "position", displayName: "Position", updateView: $updateView)
                }
                
                Spacer()
            }
            
            .onReceive(core.selectionChanged) { id in
                asset = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    asset = core.assetFolder.current
                    if let asset = asset {
                        nameState = asset.name
                    }
                }
            }
            
            .onAppear(perform: {
                asset = core.assetFolder.current
                if let asset = asset {
                    nameState = asset.name
                }
            })
        }
    }
}

struct LeftPanelView: View {
    
    let core                                : Core
    
    @State var asset                        : Asset? = nil
    
    @State var updateView                   : Bool = false
    
    @State private var selection            : UUID? = nil
        
    @State private var showPrimitives       : Bool = true
    @State private var showObjects          : Bool = true

    #if os(macOS)
    let TopRowPadding                       : CGFloat = 2
    #else
    let TopRowPadding                       : CGFloat = 5
    #endif

    init(_ core: Core)
    {
        self.core = core
        _selection = State(initialValue: core.assetFolder.currentId)
    }
    
    var body: some View {
        
        VStack {
            
            List() {
                Button(action: {
                    core.assetFolder.setCurrent()
                })
                {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Group {
                    if selection == nil {
                        Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                    } else { Color.clear }
                })
                DisclosureGroup("Primitives", isExpanded: $showPrimitives) {
                    ForEach(core.assetFolder.assets, id: \.id) { asset in
                        Button(action: {
                            core.assetFolder.setCurrent(asset)
                        })
                        {
                            Label(asset.name, systemImage: "cube")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Group {
                            if selection == asset.id {
                                Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                            } else { Color.clear }
                        })
                    }
                }
            }
        }
        
        .onReceive(core.selectionChanged) { id in
            selection = id
        }
    }
}
