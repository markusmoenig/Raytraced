//
//  RaytracedDocument.swift
//  Shared
//
//  Created by Markus Moenig on 10/3/21.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var raytracedProject: UTType {
        UTType(exportedAs: "com.Raytraced.project")
    }
}

struct RaytracedDocument: FileDocument {
    
    var core    = Core()
    var updated = false
    
    init() {
    }

    static var readableContentTypes: [UTType] { [.raytracedProject] }
    static var writableContentTypes: [UTType] { [.raytracedProject, .png] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
                let folder = try? JSONDecoder().decode(AssetFolder.self, from: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        if data.isEmpty == false {
            core.assetFolder = folder
            core.assetFolder.core = core
            
            // Make sure there is a selected asset
            if core.assetFolder.assets.count > 0 {
                core.assetFolder.current = core.assetFolder.assets[0]
            }
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        
        let encodedData = try? JSONEncoder().encode(core.assetFolder)
        if let json = String(data: encodedData!, encoding: .utf8) {
            data = json.data(using: .utf8)!
        }
        
        return .init(regularFileWithContents: data)
    }
}
