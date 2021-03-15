//
//  Views.swift
//  Raytraced
//
//  Created by Markus Moenig on 15/3/21.
//

import SwiftUI

struct ParameterView: View {
    
    let core                                : Core
        
    @State var updateView                   : Bool = false

    init(_ core: Core)
    {
        self.core = core
    }
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                
                //ForEach(options, id: \.id) { option in
                //    ParamAsTextView(core, option)
                //        .padding(4)
                //}
                
                Spacer()
            }
            
            /*
            .onReceive(self.core.modelChanged) { void in
                options = core.scriptProcessor.getOptions()
                updateView.toggle()
            }
            .onReceive(self.core.graphBuilder.selectionChanged) { id in
                options = core.scriptProcessor.getOptions()
                updateView.toggle()
            }
            .onReceive(self.core.graphBuilder.contextColorChanged) { colorText in
                let v = Float3(0,0,0)
                v.isColor = true
                options = [GraphOption(v,"Color","")]
                updateView.toggle()
            }
            .onAppear(perform: {
                options = core.scriptProcessor.getOptions()
            })*/
        }
    }
}

struct LeftPanelView: View {
    
    let core                                : Core
    
    @State var asset                        : Asset? = nil
    
    @State var updateView                   : Bool = false
    
    @State private var selection            : UUID? = nil
        
    @State private var showMaterials        : Bool = false
    @State private var showObjects          : Bool = false

    #if os(macOS)
    let TopRowPadding                       : CGFloat = 2
    #else
    let TopRowPadding                       : CGFloat = 5
    #endif

    init(_ core: Core)
    {
        self.core = core
    }
    
    var body: some View {
        
        VStack {
            
            List() {
                Button(action: {
                    //core.graphBuilder.gotoNode(cameraNode)
                })
                {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Group {
                    if core.assetFolder.currentId == nil {
                        Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                    } else { Color.clear }
                })
                
                /*
                if let sunNode = context.sunNode {
                    Button(action: {
                        core.graphBuilder.gotoNode(sunNode)
                    })
                    {
                        Label(sunNode.name, systemImage: "sun.max")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Group {
                        if selection == sunNode.id {
                            Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                        } else { Color.clear }
                    })
                }
                if let envNode = context.environmentNode {
                    Button(action: {
                        core.graphBuilder.gotoNode(envNode)
                    })
                    {
                        Label(envNode.defNode!.givenName, systemImage: "cloud.sun")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Group {
                        if selection == envNode.id {
                            Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                        } else { Color.clear }
                    })
                }
                DisclosureGroup("Materials", isExpanded: $showMaterials) {
                    ForEach(context.materialNodes, id: \.id) { node in
                        Button(action: {
                            core.graphBuilder.gotoNode(node)
                        })
                        {
                            Label(node.givenName, systemImage: "light.max")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Group {
                            if selection == node.id {
                                Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                            } else { Color.clear }
                        })
                    }
                }
                DisclosureGroup("Objects", isExpanded: $showObjects) {
                    ForEach(context.objectNodes, id: \.id) { node in
                        Button(action: {
                            core.graphBuilder.gotoNode(node)
                        })
                        {
                            Label(node.givenName, systemImage: "cube")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Group {
                            if selection == node.id {
                                Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                            } else { Color.clear }
                        })
                    }
                }*/
            }
        }
            
        /*
        
        .onReceive(self.core.modelChanged) { core in
            asset = self.core.assetFolder.getAsset("main", .Source)
            updateView.toggle()
        }
        .onReceive(self.core.graphBuilder.selectionChanged) { id in
            selection = id
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //    selection = id
            //}
        }*/
    }
}
