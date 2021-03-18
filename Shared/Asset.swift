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
        
        let box = addBox()
        addPlane()
        addLight()
        setCurrent(box)
    }
    
    /// Adds a cube to the scene
    @discardableResult func addBox(name: String = "Cube") -> Asset
    {
        let values : [String: Float] = [
            "type"       : 1,
            "position_x" : 0,
            "position_y" : 0.5,
            "position_z" : 0,
            "scale"      : 1,
            "segments_x" : 1,
            "segments_y" : 1,
            "segments_z" : 1,
            "size_x"     : 1,
            "size_y"     : 1,
            "size_z"     : 1,
        ]
        
        let asset = Asset(type: .Primitive, name: name, values: values)
        assets.append(asset)
        writeDefaultMaterialData(asset: asset, albedo: float3(1, 0, 0))
        return asset
    }
    
    /// Adds a plane to the scene
    @discardableResult func addPlane() -> Asset
    {
        let values : [String: Float] = [
            "type"       : 0,
            "position_x" : 0,
            "position_y" : 0,
            "position_z" : 0,
            "scale"      : 1,
            "segments_x" : 1,
            "segments_y" : 1,
            "segments_z" : 1,
            "size_x"     : 100,
            "size_y"     : 100,
        ]
        
        let asset = Asset(type: .Primitive, name: "Plane", values: values)
        assets.append(asset)
        writeDefaultMaterialData(asset: asset, albedo: float3(1, 1, 0))
        return asset
    }
    
    /// Adds a light to the scene
    @discardableResult func addLight(name: String = "Light") -> Asset
    {
        let values : [String: Float] = [
            "type" : 0,
            "position_x" : 0,
            "position_y" : 0,
            "position_z" : 0,
            "radius"     : 1,
            "segments_x" : 1,
            "segments_y" : 1,
            "segments_z" : 1,
            "size_x"     : 1,
            "size_y"     : 1,
            "size_z"     : 1,
            "emission_x" : 4,
            "emission_y" : 4,
            "emission_z" : 4
        ]
        
        let asset = Asset(type: .Light, name: name, values: values)
        assets.append(asset)
        return asset
    }
    
    func writeDefaultMaterialData(asset: Asset, albedo: float3 = float3(0.5, 0.5, 0.5))
    {
        asset.writeFloat3("albedo", value: albedo)
        asset.writeFloat("specular", value: 0)
        
        asset.writeFloat3("emission", value: float3(0,0,0))
        asset.writeFloat("anisotropic", value: 0)
        
        asset.writeFloat("metallic", value: 0)
        asset.writeFloat("roughness", value: 0.5)
        asset.writeFloat("subsurface", value: 0)
        asset.writeFloat("specularTint", value: 0)

        asset.writeFloat("sheen", value: 0)
        asset.writeFloat("sheenTint", value: 0)
        asset.writeFloat("clearcoat", value: 0)
        asset.writeFloat("clearcoatGloss", value: 0)
        
        asset.writeFloat("transmission", value: 0)
        asset.writeFloat("ior", value: 1.45)
        asset.writeFloat3("extinction", value: float3(0,0,0))
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
        case Primitive, Object, Light
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
    
    func readFloat(_ name: String) -> Float
    {
        var rc = Float(0)
        if let x = values[name] { rc = x }
        return rc
    }
    
    func writeFloat(_ name: String, value: Float)
    {
        values[name] = value
    }
    
    func readFloat2(_ name: String) -> float2
    {
        var rc = float2(0,0)
        if let x = values[name + "_x"] { rc.x = x }
        if let y = values[name + "_y"] { rc.y = y }
        return rc
    }
    
    func readFloat3(_ name: String) -> float3
    {
        var rc = float3(0,0,0)
        if let x = values[name + "_x"] { rc.x = x }
        if let y = values[name + "_y"] { rc.y = y }
        if let z = values[name + "_z"] { rc.z = z }
        return rc
    }
    
    func writeFloat3(_ name: String, value: float3)
    {
        values[name + "_x"] = value.x
        values[name + "_y"] = value.y
        values[name + "_z"] = value.z
    }
    
    func readUInt2(_ name: String) -> vector_uint2
    {
        var rc = vector_uint2(0,0)
        if let x = values[name + "_x"] { rc.x = UInt32(x) }
        if let y = values[name + "_y"] { rc.y = UInt32(y) }
        return rc
    }
    
    func readUInt3(_ name: String) -> vector_uint3
    {
        var rc = vector_uint3(0,0,0)
        if let x = values[name + "_x"] { rc.x = UInt32(x) }
        if let y = values[name + "_y"] { rc.y = UInt32(y) }
        if let z = values[name + "_z"] { rc.z = UInt32(z) }
        return rc
    }
        
    /// Returns BSDF in 6 float4s
    func getMaterialData() -> [float4]
    {
        var data : [float4] = []
        
        let albedo = readFloat3("albedo")
        // albedo + specular
        data.append(float4(albedo.x, albedo.y, albedo.z, readFloat("specular")))
        
        let emission = readFloat3("emission")
        // emission + anisotropic
        data.append(float4(emission.x, emission.y, emission.z, readFloat("anisotropic")))

        data.append(float4(readFloat("metallic"), readFloat("roughness"), readFloat("subsurface"), readFloat("specularTint")))
        data.append(float4(readFloat("sheen"), readFloat("sheenTint"), readFloat("clearcoat"), readFloat("clearcoatGloss")))

        data.append(float4(readFloat("transmission"), 0, 0, 0))

        let extinction = readFloat3("extinction")
        // extinction + ior
        data.append(float4(extinction.x, extinction.y, extinction.z, readFloat("ior")))

        return data
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
