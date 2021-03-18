//
//  Render.swift
//  Raytraced
//
//  Created by Markus Moenig on 10/3/21.
//

import MetalKit

class Render
{
    let core                : Core
    
    var defaultLibrary      : MTLLibrary!

    var materialIndex       : uint = 0
    
    var vertices            : [float3] = []
    var normals             : [float3] = []
    var materialIndeces     : [uint] = []
    
    var materialData        : [float4] = []
    var lightData           : [float4] = []
    
    var lightCount          : UInt32 = 0

    lazy var vertexDescriptor: MDLVertexDescriptor = {
      let vertexDescriptor = MDLVertexDescriptor()
      vertexDescriptor.attributes[0] =
        MDLVertexAttribute(name: MDLVertexAttributePosition,
                           format: .float3,
                           offset: 0, bufferIndex: 0)
      vertexDescriptor.attributes[1] =
        MDLVertexAttribute(name: MDLVertexAttributeNormal,
                           format: .float3,
                           offset: 0, bufferIndex: 1)
      vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
      vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
      return vertexDescriptor
    }()
    
    init(_ core: Core)
    {
        self.core = core
    }
    
    func restart()
    {
        vertices = []
        normals = []
        materialIndeces = []
        materialData = []
        materialIndex = 0
        lightData = []
        lightCount = 0
        buildScene()
    }
    
    func buildScene()
    {
        let allocator = MTKMeshBufferAllocator(device: core.device)
        
        for asset in core.assetFolder.assets {
            if asset.type == .Primitive {
                var mdlMesh : MDLMesh? = nil
                if asset.values["type"] == 1 {
                    // Cube
                    mdlMesh = MDLMesh.newBox(withDimensions: asset.readFloat3("size"), segments: asset.readUInt3("segments"), geometryType: .triangles, inwardNormals: false, allocator: allocator)
                } else
                if asset.values["type"] == 0 {
                    // Plane
                    mdlMesh = MDLMesh.newPlane(withDimensions: asset.readFloat2("size"), segments: asset.readUInt2("segments"), geometryType: .triangles, allocator: allocator)
                } else
                if asset.values["type"] == 2 {
                    // Sphere
                    mdlMesh = MDLMesh(sphereWithExtent: asset.readFloat3("size"),
                                      segments: asset.readUInt2("segments"),
                                      inwardNormals: false,
                                      geometryType: .triangles,
                                      allocator: allocator)
                }
                
                if let mesh = mdlMesh {
                    addPrimitiveMeshToScene(mdlMesh: mesh, asset: asset, position: asset.readFloat3("position"), scale: asset.readFloat("scale"))
                }
            } else
            if asset.type == .Light {
                
                lightCount += 1
                
                let position = asset.readFloat3("position")
                lightData.append(float4(position.x, position.y, position.z, 0))
                let emission = asset.readFloat3("emission")
                lightData.append(float4(emission.x, emission.y, emission.z, 0))
                
                if asset.values["type"] == 0 {
                    // Sphere

                    lightData.append(float4(0,0,0,0))
                    lightData.append(float4(0,0,0,0))

                    let radius = asset.readFloat("radius")
                    lightData.append(float4(radius, 4.0 * Float.pi * radius * radius, 1, 0))
                    print(radius, position, emission)
                }
            }
        }
        
        /*
        let mdlSphere = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
                              segments: [100, 100],
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        //mdlSphere.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 1)
        print(mdlSphere.vertexBuffers.count, mdlSphere.vertexDescriptor)
        */
         
        //addPrimitiveMeshToScene(mdlMesh: mdlSphere, position: float3(0, 0, 0), scale: 1)
        /*
        var error : NSError? = nil

        //var assetURL = Bundle.main.url(forResource: "Matt_substance_test", withExtension: "usdc")!
        var assetURL = Bundle.main.url(forResource: "toy_car", withExtension: "usdz")!
        //var assetURL = Bundle.main.url(forResource: "sphere", withExtension: "obj")!

        var asset = MDLAsset(url: assetURL,
                             vertexDescriptor: vertexDescriptor,
                             bufferAllocator: allocator,
                             preserveTopology: true,
                             error: &error)
        asset.loadTextures()
                                     
        print(asset.count)
        for i in 0..<asset.count {
            print(asset.object(at: i))
            if let mdlObject = asset.object(at: i) as? MDLObject {
                print(i, "year")
                
                for i in 0..<mdlObject.children.count {
                    if let mdlMesh = mdlObject.children[i] as? MDLMesh {
                        print(i, "tut")
                        addMeshToScene(mdlMesh: mdlMesh, position: float3(0,0.1,0), scale: 0.1)
                    }
                }

            }

            if let mdlMesh = asset.object(at: i) as? MDLMesh {
                print(i)
                addMeshToScene(mdlMesh: mdlMesh, position: float3(0,0.5,0), scale: 0.3)
            } else {
                print("failed")
            }
        }
        
        assetURL = Bundle.main.url(forResource: "plane", withExtension: "obj")!

        asset = MDLAsset(url: assetURL,
                             vertexDescriptor: vertexDescriptor,
                             bufferAllocator: allocator)
        
        if let mdlMesh = asset.object(at: 0) as? MDLMesh {
            addMeshToScene(mdlMesh: mdlMesh, position: float3(0,0,0), scale: 10)
            print("build scene finished")
        }
        */
    }
    
    func addPrimitiveMeshToScene(mdlMesh: MDLMesh, asset: Asset, position: float3, scale: Float)
    {
        guard let positionAttribute = mdlMesh.vertexDescriptor.attributeNamed(MDLVertexAttributePosition),
        positionAttribute.format == .float3,
        let positionData = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition, as: .float3),
        let normalAttribute = mdlMesh.vertexDescriptor.attributeNamed(MDLVertexAttributeNormal), normalAttribute.format == .float3,
        let normalData = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal, as: .float3)
        else { return }

        guard let submeshes = mdlMesh.submeshes as? [MDLSubmesh] else { return }
        
        materialData += asset.getMaterialData()

        for submesh in submeshes {
            var indices = submesh.indexBuffer.map().bytes.bindMemory(to: UInt16.self, capacity: submesh.indexCount)
            for _ in 0..<submesh.indexCount {
                let index = Int(indices.pointee)
                let positionPtr = positionData.dataStart + index * positionData.stride
                let normalsPtr = normalData.dataStart + index * normalData.stride
                let newPosition = positionPtr.assumingMemoryBound(to: float3.self).pointee
                //let newNormal = normalsPtr.assumingMemoryBound(to: float3.self).pointee
      
                let f1 = normalsPtr.assumingMemoryBound(to: Float.self).pointee
                let f2 = (normalsPtr + MemoryLayout<Float>.stride).assumingMemoryBound(to: Float.self).pointee
                let f3 = (normalsPtr + MemoryLayout<Float>.stride * 2).assumingMemoryBound(to: Float.self).pointee
                let newNormal: float3 = [f1, f2, f3]
      
                vertices.append(newPosition * scale + position)
                normals.append(newNormal)
                indices = indices.advanced(by: 1)
                
                materialIndeces.append(materialIndex)
            }
        }
        
        materialIndex += 1
    }

    /// Adds the given mesh to the scene
    func addMeshToScene(mdlMesh: MDLMesh, position: float3, scale: Float)
    {
        guard let mdlSubmeshes = mdlMesh.submeshes as? [MDLSubmesh] else { return }
        let mesh = try! MTKMesh(mesh: mdlMesh, device: core.device)
        let count = mesh.vertexBuffers[0].buffer.length / MemoryLayout<float3>.size

        let positionBuffer = mesh.vertexBuffers[0].buffer
        let normalsBuffer = mesh.vertexBuffers[1].buffer
        let normalsPtr = normalsBuffer.contents().bindMemory(to: float3.self, capacity: count)
        let positionPtr = positionBuffer.contents().bindMemory(to: float3.self, capacity: count)
        for (mdlIndex, submesh) in mesh.submeshes.enumerated() {
            let indexBuffer = submesh.indexBuffer.buffer
            let offset = submesh.indexBuffer.offset
            let indexPtr = indexBuffer.contents().advanced(by: offset)
            var indices = indexPtr.bindMemory(to: uint.self, capacity: submesh.indexCount)
            for _ in 0..<submesh.indexCount {
                let index = Int(indices.pointee)
                vertices.append(positionPtr[index] * scale + position)
                normals.append(normalsPtr[index])
                indices = indices.advanced(by: 1)
                let mdlSubmesh = mdlSubmeshes[mdlIndex]
                let color: float3
                if let material = mdlSubmesh.material {
                    //print(material.name)

                    //for i in 0..<material.count {
                        //print(material[i]?.name)
                    //}
                    
                    if let baseColor = material.property(with: .baseColor) {
                        
                        if let sourceTexture = baseColor.textureSamplerValue?.texture {
                            print("has source texture", sourceTexture.name)
                        }
                        
                        //print(baseColor.type, baseColor.float3Value)
                        //if baseColor.type == .float3 {

                        //scolor = baseColor.float3Value
                        color = float3(baseColor.float4Value.x, baseColor.float4Value.y, baseColor.float4Value.z)
                        //colors.append(color)

                            
                        //} else {
                         //   print(baseColor.type)
                            //color = [1, 0, 0]
                            //colors.append(color)

                        //}
                    } else {
                        color = [1, 0, 0]
                        //colors.append(color)
                    }
                    
                    //if let roughness = material.property(with: .roughness) {
                        //print(roughness.floatValue)
                    //}

                }
                /*
                if let baseColor = mdlSubmesh.material?.property(with: .baseColor),
                   baseColor.type == .float3 {
                    color = baseColor.float3Value
                } else {
                    color = [1, 0, 0]
                }
                colors.append(color)
                */
            }
        }
    }
    
    /// Allocate a texture of the given size
    func allocateTexture2D(width: Int, height: Int, format: MTLPixelFormat = .rgba16Float) -> MTLTexture?
    {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = format
        textureDescriptor.width = width == 0 ? 1 : width
        textureDescriptor.height = height == 0 ? 1 : height
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        return core.device.makeTexture(descriptor: textureDescriptor)
    }
    
    func setup()
    {
    }
    
    func viewSizeWillChange(size: SIMD2<Int>)
    {        
    }
    
    func render()
    {
    }
}
