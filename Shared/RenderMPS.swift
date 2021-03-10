//
//  RenderMPS.swift
//  Raytraced
//
//  Created by Markus Moenig on 10/3/21.
//

import MetalKit
import MetalPerformanceShaders

class RenderMPS : Render
{
    var renderPipeline      : MTLRenderPipelineState!
    var rayPipeline         : MTLComputePipelineState!
    var shadePipelineState  : MTLComputePipelineState!
    var accumulatePipeline  : MTLComputePipelineState!
    var shadowPipeline      : MTLComputePipelineState!
    
    var vertexPositionBuffer: MTLBuffer!
    var vertexNormalBuffer  : MTLBuffer!
    var vertexColorBuffer   : MTLBuffer!
    var indexBuffer         : MTLBuffer!
    var uniformBuffer       : MTLBuffer!
    var randomBuffer        : MTLBuffer!
    
    var rayBuffer           : MTLBuffer!
    var shadowRayBuffer     : MTLBuffer!
    var intersectionBuffer  : MTLBuffer!

    let intersectionStride  = MemoryLayout<MPSIntersectionDistancePrimitiveIndexCoordinates>.stride
    
    var semaphore           : DispatchSemaphore!
    var size                = SIMD2<Int>(0,0)
    var randomBufferOffset  = 0
    var uniformBufferOffset = 0
    var uniformBufferIndex  = 0
    var frameIndex          : uint = 0
    
    var accumulationTarget  : MTLTexture!
    var renderTarget        : MTLTexture!
    
    var intersector         : MPSRayIntersector!
    let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 255) & ~255

    var accelerationStructure: MPSTriangleAccelerationStructure!

    let rayStride           = MemoryLayout<MPSRayOriginMinDistanceDirectionMaxDistance>.stride + MemoryLayout<float3>.stride
    let maxFramesInFlight   = 3

    override func setup()
    {
        defaultLibrary = core.device.makeDefaultLibrary()

        semaphore = DispatchSemaphore.init(value: maxFramesInFlight)

        buildPipelines(view: core.view)
        buildScene()
        buildBuffers()
        
        intersector = MPSRayIntersector(device: core.device)
        intersector?.rayDataType = .originMinDistanceDirectionMaxDistance
        intersector?.rayStride = rayStride
        
        accelerationStructure = MPSTriangleAccelerationStructure(device: core.device)
        accelerationStructure?.vertexBuffer = vertexPositionBuffer
        accelerationStructure?.triangleCount = vertices.count / 3
        accelerationStructure?.rebuild()
    }
    
    override func render()
    {
        semaphore.wait()
        
        guard let commandBuffer = core.commandQueue.makeCommandBuffer() else {
            return
        }
        
        commandBuffer.addCompletedHandler { cb in
          self.semaphore.signal()
        }
        
        update()
        
        // MARK: generate rays
        let width = Int(size.x)
        let height = Int(size.y)
        let threadsPerGroup = MTLSizeMake(8, 8, 1)
        let threadGroups = MTLSizeMake((width + threadsPerGroup.width - 1) / threadsPerGroup.width,
                                       (height + threadsPerGroup.height - 1) / threadsPerGroup.height,
                                       1)
        var computeEncoder = commandBuffer.makeComputeCommandEncoder()
        computeEncoder?.label = "Generate Rays"
        computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                                  index: 0)
        computeEncoder?.setBuffer(rayBuffer, offset: 0, index: 1)
        computeEncoder?.setBuffer(randomBuffer, offset: randomBufferOffset,
                                  index: 2)
        computeEncoder?.setTexture(renderTarget, index: 0)
        computeEncoder?.setComputePipelineState(rayPipeline)
        computeEncoder?.dispatchThreadgroups(threadGroups,
                                             threadsPerThreadgroup: threadsPerGroup)
        computeEncoder?.endEncoding()
        
        for _ in 0..<3 {
            // MARK: generate intersections between rays and model triangles
            intersector?.intersectionDataType = .distancePrimitiveIndexCoordinates
            intersector?.encodeIntersection(
                commandBuffer: commandBuffer,
                intersectionType: .nearest,
                rayBuffer: rayBuffer,
                rayBufferOffset: 0,
                intersectionBuffer: intersectionBuffer,
                intersectionBufferOffset: 0,
                rayCount: width * height,
                accelerationStructure: accelerationStructure)
          
            // MARK: shading
          
            computeEncoder = commandBuffer.makeComputeCommandEncoder()
            computeEncoder?.label = "Shading"
            computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                                      index: 0)
            computeEncoder?.setBuffer(rayBuffer, offset: 0, index: 1)
            computeEncoder?.setBuffer(shadowRayBuffer, offset: 0, index: 2)
            computeEncoder?.setBuffer(intersectionBuffer, offset: 0, index: 3)
            computeEncoder?.setBuffer(vertexColorBuffer, offset: 0, index: 4)
            computeEncoder?.setBuffer(vertexNormalBuffer, offset: 0, index: 5)
            computeEncoder?.setBuffer(randomBuffer, offset: randomBufferOffset,
                                      index: 6)
            computeEncoder?.setTexture(renderTarget, index: 0)
            computeEncoder?.setComputePipelineState(shadePipelineState!)
            computeEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
            computeEncoder?.endEncoding()
          
            // MARK: shadows
            
            intersector?.label = "Shadows Intersector"
            intersector?.intersectionDataType = .distance
            intersector?.encodeIntersection(
                commandBuffer: commandBuffer,
                intersectionType: .any,
                rayBuffer: shadowRayBuffer,
                rayBufferOffset: 0,
                intersectionBuffer: intersectionBuffer,
                intersectionBufferOffset: 0,
                rayCount: width * height,
                accelerationStructure: accelerationStructure)
          
            computeEncoder = commandBuffer.makeComputeCommandEncoder()
            computeEncoder?.label = "Shadows"
            computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                                    index: 0)
            computeEncoder?.setBuffer(shadowRayBuffer, offset: 0, index: 1)
            computeEncoder?.setBuffer(intersectionBuffer, offset: 0, index: 2)
            computeEncoder?.setTexture(renderTarget, index: 0)
            computeEncoder?.setComputePipelineState(shadowPipeline!)
            computeEncoder?.dispatchThreadgroups(threadGroups,threadsPerThreadgroup: threadsPerGroup)
            computeEncoder?.endEncoding()
        }
        
        // MARK: accumulation
        
        computeEncoder = commandBuffer.makeComputeCommandEncoder()
        computeEncoder?.label = "Accumulation"
        computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                                  index: 0)
        computeEncoder?.setTexture(renderTarget, index: 0)
        computeEncoder?.setTexture(accumulationTarget, index: 1)
        computeEncoder?.setComputePipelineState(accumulatePipeline)
        computeEncoder?.dispatchThreadgroups(threadGroups,
                                             threadsPerThreadgroup: threadsPerGroup)
        computeEncoder?.endEncoding()
        
        guard let descriptor = core.view.currentRenderPassDescriptor,
          let renderEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: descriptor) else {
              return
        }
        renderEncoder.setRenderPipelineState(renderPipeline!)
        
        // MARK: draw call
        renderEncoder.setFragmentTexture(accumulationTarget, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        guard let drawable = core.view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    override func viewSizeWillChange(size: SIMD2<Int>)
    {
        self.size = size
        frameIndex = 0
        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = .rgba32Float
        renderTargetDescriptor.textureType = .type2D
        renderTargetDescriptor.width = Int(size.x)
        renderTargetDescriptor.height = Int(size.y)
        renderTargetDescriptor.storageMode = .private
        renderTargetDescriptor.usage = [.shaderRead, .shaderWrite]
        
        renderTarget = core.device.makeTexture(descriptor: renderTargetDescriptor)
        
        let rayCount = Int(size.x * size.y)
        rayBuffer = core.device.makeBuffer(length: rayStride * rayCount, options: .storageModePrivate)
        shadowRayBuffer = core.device.makeBuffer(length: rayStride * rayCount,
                                                 options: .storageModePrivate)
        
        accumulationTarget = core.device.makeTexture(descriptor: renderTargetDescriptor)
        intersectionBuffer = core.device.makeBuffer(length: intersectionStride * rayCount, options: .storageModePrivate)
    }
    
    /// Build the pipelines
    func buildPipelines(view: MTKView)
    {
        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.sampleCount = view.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
      
        let device = core.device
        
        do {
            computeDescriptor.computeFunction = defaultLibrary.makeFunction(name: "shadowKernel")
            shadowPipeline = try device?.makeComputePipelineState(descriptor: computeDescriptor,
                                                                  options: [],
                                                                  reflection: nil)
        
            computeDescriptor.computeFunction = defaultLibrary.makeFunction(name: "shadeKernel")
            shadePipelineState = try device?.makeComputePipelineState(descriptor: computeDescriptor,
                                                                      options: [],
                                                                      reflection: nil)
        
            computeDescriptor.computeFunction = defaultLibrary.makeFunction(name: "accumulateKernel")
            accumulatePipeline = try device?.makeComputePipelineState(descriptor: computeDescriptor,
                                                                      options: [],
                                                                      reflection: nil)
        
            computeDescriptor.computeFunction = defaultLibrary.makeFunction(name: "primaryRays")
            rayPipeline = try device?.makeComputePipelineState(descriptor: computeDescriptor, options: [], reflection: nil)
        
            renderPipeline = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Build the required buffers
    func buildBuffers()
    {
        let uniformBufferSize = alignedUniformsSize * maxFramesInFlight

        let options: MTLResourceOptions = {
          #if os(iOS)
          return .storageModeShared
          #else
          return .storageModeManaged
          #endif
        } ()
        
        let device = core.device!
        
        uniformBuffer = device.makeBuffer(length: uniformBufferSize, options: options)
        randomBuffer = device.makeBuffer(length: 256 * MemoryLayout<float2>.stride * maxFramesInFlight, options: options)
        vertexPositionBuffer = device.makeBuffer(bytes: &vertices, length: vertices.count * MemoryLayout<float3>.stride, options: options)
        vertexColorBuffer = device.makeBuffer(bytes: &colors, length: colors.count * MemoryLayout<float3>.stride, options: options)
        vertexNormalBuffer = device.makeBuffer(bytes: &normals, length: normals.count * MemoryLayout<float3>.stride, options: options)
    }
    
    func update() {
        updateUniforms()
        updateRandomBuffer()
        uniformBufferIndex = (uniformBufferIndex + 1) % maxFramesInFlight
    }
    
    func updateUniforms() {
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        let pointer = uniformBuffer!.contents().advanced(by: uniformBufferOffset)
        let uniforms = pointer.bindMemory(to: Uniforms.self, capacity: 1)
      
        var camera = Camera()
        camera.position = float3(0.0, 1.0, 3.38)
        camera.forward = float3(0.0, 0.0, -1.0)
        camera.right = float3(1.0, 0.0, 0.0)
        camera.up = float3(0.0, 1.0, 0.0)
      
        let fieldOfView = 45.0 * (Float.pi / 180.0)
        let aspectRatio = Float(size.x) / Float(size.y)
        let imagePlaneHeight = tanf(fieldOfView / 2.0)
        let imagePlaneWidth = aspectRatio * imagePlaneHeight
      
        camera.right *= imagePlaneWidth
        camera.up *= imagePlaneHeight
      
        var light = AreaLight()
        light.position = float3(0.0, 1.98, 0.0)
        light.forward = float3(0.0, -1.0, 0.0)
        light.right = float3(0.25, 0.0, 0.0)
        light.up = float3(0.0, 0.0, 0.25)
        light.color = float3(4.0, 4.0, 4.0)
      
        uniforms.pointee.camera = camera
        uniforms.pointee.light = light
      
        uniforms.pointee.width = uint(size.x)
        uniforms.pointee.height = uint(size.y)
        uniforms.pointee.blocksWide = ((uniforms.pointee.width) + 15) / 16
        uniforms.pointee.frameIndex = frameIndex
        frameIndex += 1
        #if os(OSX)
        uniformBuffer?.didModifyRange(uniformBufferOffset..<(uniformBufferOffset + alignedUniformsSize))
        #endif
    }
    
    func updateRandomBuffer() {
        randomBufferOffset = 256 * MemoryLayout<float2>.stride * uniformBufferIndex
        let pointer = randomBuffer!.contents().advanced(by: randomBufferOffset)
        var random = pointer.bindMemory(to: float2.self, capacity: 256)
        for _ in 0..<256 {
            random.pointee = float2(Float(drand48()), Float(drand48()) )
            random = random.advanced(by: 1)
        }
        #if os(OSX)
        randomBuffer?.didModifyRange(randomBufferOffset..<(randomBufferOffset + 256 * MemoryLayout<float2>.stride))
        #endif
    }
}
