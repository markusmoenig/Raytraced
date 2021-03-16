//
//  Asset.swift
//  Raytraced
//
//  Created by Markus Moenig on 15/3/21.
//

import Foundation

class AssetFolder       : Codable
{
    var assets          : [Asset] = []
    
    var core            : Core!
    
    var current         : Asset? = nil
    var currentId       : UUID? = nil

    var customSize      : SIMD2<Int>? = nil

    private enum CodingKeys: String, CodingKey {
        case assets
        case currentId
    }
    
    init()
    {
    }
    
    func setup(_ core: Core)
    {
        self.core = core
        /*
        guard let path = Bundle.main.path(forResource: "Shader", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .Shader, name: "Shader", value: value))
            current = assets[0]
            currentId = assets[0].id
        }*/
        
        addBox()
        setCurrent(addPlane())
    }
    
    /// Adds a cube to the scene
    @discardableResult func addBox() -> Asset
    {
        let values : [String: Float] = [
            "type" : 0,
            "position_x" : 0,
            "position_y" : 0.5,
            "position_z" : 0,
            "scale" : 1,
            "segments_x" : 10,
            "segments_y" : 10,
            "segments_z" : 10,
            "size_x" : 1,
            "size_y" : 1,
            "size_z" : 1,
        ]
        
        let asset = Asset(type: .Primitive, name: "Cube", values: values)
        assets.append(asset)
        return asset
    }
    
    /// Adds a plane to the scene
    @discardableResult func addPlane() -> Asset
    {
        let values : [String: Float] = [
            "type" : 1,
            "position_x" : 0,
            "position_y" : 0,
            "position_z" : 0,
            "scale" : 1,
            "segments_x" : 10,
            "segments_y" : 10,
            "size_x" : 100,
            "size_y" : 100,
        ]
        
        let asset = Asset(type: .Primitive, name: "Plane", values: values)
        assets.append(asset)
        return asset
    }
    
    /// Sets the current asset
    func setCurrent(_ asset: Asset? = nil)
    {
        current = asset
        if let asset = asset {
            currentId = asset.id
        } else {
            currentId = nil
        }
        
        core.selectionChanged.send(currentId)
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assets = try container.decode([Asset].self, forKey: .assets)
        //if let id = try container.decodeIfPresent(UUID?.self, forKey: .currentId) {
            //select(id!)
        //}
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assets, forKey: .assets)
        try container.encode(currentId, forKey: .currentId)
    }
}

class Asset         : Codable, Equatable
{
    enum AssetType  : Int, Codable {
        case Primitive, Object
    }
    
    var type        : AssetType = .Primitive
    var id          = UUID()
    
    var name        = ""
    var values      : [String: Float] = [:]
        
    var data        : Data? = nil
    
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case name
        case values
        case uuid
        case data
    }
    
    init(type: AssetType, name: String, values: [String: Float] = [:], data: Data? = nil)
    {
        self.type = type
        self.name = name
        self.values = values
        self.data = data
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AssetType.self, forKey: .type)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        values = try container.decode([String: Float].self, forKey: .values)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(values, forKey: .values)
        try container.encode(data, forKey: .data)
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
