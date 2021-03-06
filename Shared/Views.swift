//
//  Views.swift
//  Raytraced
//
//  Created by Markus Moenig on 15/3/21.
//

import SwiftUI

struct LabelledDivider: View {

    let label: String
    let horizontalPadding: CGFloat
    let color: Color

    init(label: String, horizontalPadding: CGFloat = 5, color: Color = .gray) {
        self.label = label
        self.horizontalPadding = horizontalPadding
        self.color = color
    }

    var body: some View {
        HStack {
            line
                .padding(.top, 2)
            Text(label).foregroundColor(color)
            line
                .padding(.bottom, 2)
        }
    }

    var line: some View {
        VStack { Divider().background(color) }.padding(horizontalPadding)
    }
}

struct FloatParamView: View {
    
    let core                                : Core
        
    var valueName                           : String
    var displayName                         : String
    
    @State var xValueText                   : String = ""
    @State var yValueText                   : String = ""
    
    init(core: Core, valueName: String, displayName: String)
    {
        self.core = core
        self.valueName = valueName
        self.displayName = displayName
        
        if let asset = core.assetFolder.current {
            _xValueText = State(initialValue: String(format: "%.03g", asset.values[valueName]!))
        }
    }
    
    var body: some View {

        HStack(alignment: .top) {
            Text(displayName)
                .frame(minWidth: 100, idealWidth: 100, maxWidth: 100, alignment: .leading)
                if let asset = core.assetFolder.current {
                    TextField(valueName, text: $xValueText, onEditingChanged: { (changed) in
                    },
                    onCommit: {
                        asset.values[valueName] = Float(xValueText)
                        core.renderer.restart()
                    } )
                }
        }
        .padding(2)

        .onReceive(core.modelChanged) { id in
            if let asset = core.assetFolder.current {
                if let xValue = asset.values[valueName] {
                    xValueText = String(format: "%.03g", xValue)
                }
            }
        }
    }
}

struct Float2ParamView: View {
    
    let core                                : Core
        
    var valueName                           : String
    var displayName                         : String
    
    @State var xValueText                   : String = ""
    @State var yValueText                   : String = ""
    
    init(core: Core, valueName: String, displayName: String)
    {
        self.core = core
        self.valueName = valueName
        self.displayName = displayName
        
        if let asset = core.assetFolder.current {
            _xValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_x"]!))
            _yValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_y"]!))
        }
    }
    
    var body: some View {

        VStack(alignment: .leading) {
            Text(displayName)
            HStack {
                if let asset = core.assetFolder.current {
                    TextField(valueName, text: $xValueText, onEditingChanged: { (changed) in
                    },
                    onCommit: {
                        asset.values[valueName + "_x"] = Float(xValueText)
                        core.renderer.restart()
                    } )
                    .border(Color.red)
                    TextField(valueName, text: $yValueText, onEditingChanged: { (changed) in
                        asset.values[valueName + "_y"] = Float(yValueText)
                        core.renderer.restart()
                    },
                    onCommit: {
                    } )
                    .border(Color.green)
                }
            }
            .padding(2)
        }
        
        .onReceive(core.modelChanged) { id in
            if let asset = core.assetFolder.current {
                xValueText = String(format: "%.03g", asset.values[valueName + "_x"]!)
                yValueText = String(format: "%.03g", asset.values[valueName + "_y"]!)
            }
        }
    }
}

struct Float3ParamView: View {
    
    let core                                : Core
        
    var valueName                           : String
    var displayName                         : String
    
    @State var xValueText                   : String = ""
    @State var yValueText                   : String = ""
    @State var zValueText                   : String = ""
    
    init(core: Core, valueName: String, displayName: String)
    {
        self.core = core
        self.valueName = valueName
        self.displayName = displayName
        
        if let asset = core.assetFolder.current {
            _xValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_x"]!))
            _yValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_y"]!))
            _zValueText = State(initialValue: String(format: "%.03g", asset.values[valueName + "_z"]!))
        }
    }
    
    var body: some View {

        VStack(alignment: .leading) {
            Text(displayName)
            HStack {
                if let asset = core.assetFolder.current {

                    TextField(valueName, text: $xValueText, onEditingChanged: { (changed) in
                    },
                    onCommit: {
                        asset.values[valueName + "_x"] = Float(xValueText)
                        core.renderer.restart()
                    } )
                    .border(Color.red)
                    TextField(valueName, text: $yValueText, onEditingChanged: { (changed) in
                        asset.values[valueName + "_y"] = Float(yValueText)
                        core.renderer.restart()
                    },
                    onCommit: {
                    } )
                    .border(Color.green)
                    TextField(valueName, text: $zValueText, onEditingChanged: { (changed) in
                        asset.values[valueName + "_z"] = Float(zValueText)
                        core.renderer.restart()
                    },
                    onCommit: {
                    } )
                    .border(Color.blue)
                }
            }
            .padding(2)
        }
        
        .onReceive(core.modelChanged) { id in
            if let asset = core.assetFolder.current {
                if let xValue = asset.values[valueName + "_x"] {
                    xValueText = String(format: "%.03g", xValue)
                }
                if let yValue = asset.values[valueName + "_y"] {
                    yValueText = String(format: "%.03g", yValue)
                }
                if let zValue = asset.values[valueName + "_z"] {
                    zValueText = String(format: "%.03g", zValue)
                }
            }
        }
    }
}

struct Float3GlobalView: View {
    
    let core                                : Core
        
    var valueName                           : String
    var displayName                         : String
    
    @State var xValueText                   : String = ""
    @State var yValueText                   : String = ""
    @State var zValueText                   : String = ""
    
    init(core: Core, valueName: String, displayName: String)
    {
        self.core = core
        self.valueName = valueName
        self.displayName = displayName
        
        let values = core.assetFolder.values
        
        if values[valueName + "_x"] != nil {
            _xValueText = State(initialValue: String(format: "%.03g", values[valueName + "_x"]!))
            _yValueText = State(initialValue: String(format: "%.03g", values[valueName + "_y"]!))
            _zValueText = State(initialValue: String(format: "%.03g", values[valueName + "_z"]!))
        }
    }
    
    var body: some View {

        VStack(alignment: .leading) {
            Text(displayName)
            HStack {
                TextField(valueName, text: $xValueText, onEditingChanged: { (changed) in
                },
                onCommit: {
                    core.assetFolder.values[valueName + "_x"] = Float(xValueText)
                    core.renderer.restart()
                } )
                .border(Color.red)
                TextField(valueName, text: $yValueText, onEditingChanged: { (changed) in
                    core.assetFolder.values[valueName + "_y"] = Float(yValueText)
                    core.renderer.restart()
                },
                onCommit: {
                } )
                .border(Color.green)
                TextField(valueName, text: $zValueText, onEditingChanged: { (changed) in
                    core.assetFolder.values[valueName + "_z"] = Float(zValueText)
                    core.renderer.restart()
                },
                onCommit: {
                } )
                .border(Color.blue)
            }
            .padding(2)
        }
        
        .onReceive(core.modelChanged) { id in
            let values = core.assetFolder.values
            if values[valueName + "_x"] != nil {
                if let xValue = values[valueName + "_x"] {
                    xValueText = String(format: "%.03g", xValue)
                }
                if let yValue = values[valueName + "_y"] {
                    yValueText = String(format: "%.03g", yValue)
                }
                if let zValue = values[valueName + "_z"] {
                    zValueText = String(format: "%.03g", zValue)
                }
            }
        }
    }
}

struct MaterialGroup1View: View {
    
    let core                                : Core
    
    var asset                               : Asset

    init(core: Core, asset: Asset)
    {
        self.core = core
        self.asset = asset
    }
    
    var body: some View {
            
        Float3ParamView(core: core, valueName: "albedo", displayName: "Albedo")
        FloatParamView(core: core, valueName: "metallic", displayName: "Metallic")
        FloatParamView(core: core, valueName: "roughness", displayName: "Roughness")
        
        FloatParamView(core: core, valueName: "specular", displayName: "Specular")
        FloatParamView(core: core, valueName: "specularTint", displayName: "Specular Tint")
        FloatParamView(core: core, valueName: "subsurface", displayName: "Subsurface")
        FloatParamView(core: core, valueName: "anisotropic", displayName: "Anisotropic")
    }
}

struct MaterialGroup2View: View {
    
    let core                                : Core
    
    var asset                               : Asset

    init(core: Core, asset: Asset)
    {
        self.core = core
        self.asset = asset
    }
    
    var body: some View {
        
        FloatParamView(core: core, valueName: "sheen", displayName: "Sheen")
        FloatParamView(core: core, valueName: "sheenTint", displayName: "SheenTint")
        
        FloatParamView(core: core, valueName: "clearcoat", displayName: "Clearcoat")
        FloatParamView(core: core, valueName: "clearcoatGloss", displayName: "Clearcoat Gloss")
        
        FloatParamView(core: core, valueName: "transmission", displayName: "Transmission")
        FloatParamView(core: core, valueName: "ior", displayName: "Index of Refr.")
        
        Float3ParamView(core: core, valueName: "emission", displayName: "Emission")
        Float3ParamView(core: core, valueName: "extinction", displayName: "Extinction")
    }
}

struct MaterialView: View {
    
    let core                                : Core
    
    var asset                               : Asset

    init(core: Core, asset: Asset)
    {
        self.core = core
        self.asset = asset
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            MaterialGroup1View(core: core, asset: asset)
            MaterialGroup2View(core: core, asset: asset)
        }
    }
}

struct ParameterView: View {
    
    let core                                : Core
    
    @State var asset                        : Asset? = nil
    
    @State var nameState                    : String = ""
    @State var updateView                   : Bool = false
    
    @State var primitiveMenuName            : String = ""
    @State var lightMenuName                : String = ""

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
                    },
                    onCommit: {
                        currentAsset.name = nameState
                        core.assetFolder.setCurrent()
                        core.assetFolder.setCurrent(asset)
                    } )
                    .padding(2)
                    
                    Float3ParamView(core: core, valueName: "position", displayName: "Position")
                    
                    if currentAsset.type == .Primitive {
                        LabelledDivider(label: "Shape")

                        Menu {
                            Button("Plane", action: {
                                currentAsset.values["type"] = 0
                                currentAsset.values["size_x"] = 1
                                currentAsset.values["size_y"] = 1
                                currentAsset.values["segments_x"] = 1
                                currentAsset.values["segments_y"] = 1
                                core.renderer.restart()
                                primitiveMenuName = "Type: Plane"
                                core.modelChanged.send()
                            })
                            Button("Cube", action: {
                                currentAsset.values["type"] = 1
                                currentAsset.values["size_x"] = 1
                                currentAsset.values["size_y"] = 1
                                currentAsset.values["size_z"] = 1
                                currentAsset.values["segments_x"] = 1
                                currentAsset.values["segments_y"] = 1
                                currentAsset.values["segments_z"] = 1
                                core.renderer.restart()
                                primitiveMenuName = "Type: Cube"
                                core.modelChanged.send()
                            })
                            Button("Sphere", action: {
                                currentAsset.values["type"] = 2
                                currentAsset.values["size_x"] = 0.5
                                currentAsset.values["size_y"] = 0.5
                                currentAsset.values["size_z"] = 0.5
                                currentAsset.values["segments_x"] = 50
                                currentAsset.values["segments_y"] = 50
                                currentAsset.values["segments_z"] = 50
                                primitiveMenuName = "Type: Sphere"
                                core.renderer.restart()
                                core.modelChanged.send()
                            })
                        }
                        label: {
                            Text(primitiveMenuName)
                        }
                        
                        if let type = currentAsset.values["type"] {
                            if type == 0 {
                                Float2ParamView(core: core, valueName: "size", displayName: "Size")
                                Float2ParamView(core: core, valueName: "segments", displayName: "Segments")
                            } else
                            if type == 1 || type == 2 {
                                Float3ParamView(core: core, valueName: "size", displayName: "Size")
                                Float3ParamView(core: core, valueName: "segments", displayName: "Segments")
                            }
                        }
                        
                        LabelledDivider(label: "Material")
                        MaterialView(core: core, asset: currentAsset)
                    }
                    else
                    if currentAsset.type == .Light {
                        
                        Float3ParamView(core: core, valueName: "emission", displayName: "Emission")

                        LabelledDivider(label: "Light Settings")

                        Menu {
                            Button("Sphere", action: {
                                currentAsset.values["type"] = 0
                                core.renderer.restart()
                                lightMenuName = "Type: Sphere"
                                core.modelChanged.send()
                            })
                            Button("Rect", action: {
                                currentAsset.values["type"] = 1
                                core.renderer.restart()
                                lightMenuName = "Type: Rect"
                                core.modelChanged.send()
                            })
                        }
                        label: {
                            Text(lightMenuName)
                        }
                        
                        if let type = currentAsset.values["type"] {
                            if type == 0 {
                                FloatParamView(core: core, valueName: "radius", displayName: "Radius")
                            } else {
                                Float3ParamView(core: core, valueName: "v1", displayName: "v1")
                                Float3ParamView(core: core, valueName: "v2", displayName: "v2")
                            }
                        }
                    }
                }
                else {
                    // Camera
                    
                    Float3GlobalView(core: core, valueName: "origin", displayName: "Origin")
                    Float3GlobalView(core: core, valueName: "lookAt", displayName: "Look At")
                }
                                
                Spacer()
            }
            
            .onReceive(core.selectionChanged) { id in
                asset = core.assetFolder.current

                if let asset = asset {
                    nameState = asset.name
                    primitiveMenuName = "Type: " + getPrimitiveTypeString(asset)
                    lightMenuName = "Type: " + getLightTypeString(asset)
                }
                core.modelChanged.send()
            }
            
            .onAppear(perform: {
                asset = core.assetFolder.current
                if let asset = asset {
                    nameState = asset.name
                    primitiveMenuName = "Type: " + getPrimitiveTypeString(asset)
                    lightMenuName = "Type: " + getLightTypeString(asset)
                }
            })
        }
    }
    
    func getPrimitiveTypeString(_ asset: Asset) -> String
    {
        let type = asset.values["type"]
        if type == 0 { return "Plane" }
        if type == 1 { return "Cube" }
        if type == 2 { return "Sphere" }
        return ""
    }
    
    func getLightTypeString(_ asset: Asset) -> String
    {
        let type = asset.values["type"]
        if type == 0 { return "Sphere" }
        if type == 1 { return "Rect" }
        return ""
    }
}

struct LeftPanelView: View {
    
    let core                                : Core
    
    @State var asset                        : Asset? = nil
    
    @State var updateView                   : Bool = false
    
    @State private var selection            : UUID? = nil
        
    @State private var showLights           : Bool = true
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
                DisclosureGroup("Lights", isExpanded: $showLights) {
                    ForEach(core.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Light {
                            Button(action: {
                                core.assetFolder.setCurrent(asset)
                            })
                            {
                                Label(asset.name, systemImage: "lightbulb")
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
                DisclosureGroup("Primitives", isExpanded: $showPrimitives) {
                    ForEach(core.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Primitive {
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
        }
        
        .onReceive(core.selectionChanged) { id in
            selection = id
        }
    }
}
