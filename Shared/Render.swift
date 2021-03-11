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

    var vertices            : [float3] = []
    var normals             : [float3] = []
    var colors              : [float3] = []
    
    lazy var vertexDescriptor: MDLVertexDescriptor = {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                            format: .float2,
                                                            offset: 0, bufferIndex: 1)
      vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
      vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
      return vertexDescriptor
    }()
    
    init(_ core: Core)
    {
        self.core = core
    }
    
    func buildScene()
    {
        let allocator = MTKMeshBufferAllocator(device: core.device)

        /*
        let mdlSphere = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
                              segments: [100, 100],
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        mdlSphere.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 1)
        print(mdlSphere.vertexBuffers.count, mdlSphere.vertexDescriptor)
        */        
        
        var assetURL = Bundle.main.url(forResource: "sphere", withExtension: "obj")!

        var asset = MDLAsset(url: assetURL,
                             vertexDescriptor: vertexDescriptor,
                             bufferAllocator: allocator)
        
        if let mdlMesh = asset.object(at: 0) as? MDLMesh {
            addMeshToScene(mdlMesh: mdlMesh, position: float3(0,0.5,0), scale: 0.3)
        }
        
        assetURL = Bundle.main.url(forResource: "plane", withExtension: "obj")!

        asset = MDLAsset(url: assetURL,
                             vertexDescriptor: vertexDescriptor,
                             bufferAllocator: allocator)
        
        if let mdlMesh = asset.object(at: 0) as? MDLMesh {
            addMeshToScene(mdlMesh: mdlMesh, position: float3(0,0,0), scale: 10)
            print("build scene finished")
        }
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
                if let baseColor = mdlSubmesh.material?.property(with: .baseColor),
                   baseColor.type == .float3 {
                    color = baseColor.float3Value
                } else {
                    color = [1, 0, 0]
                }
                colors.append(color)
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
