//
//  Core.swift
//  Raytraced
//
//  Created by Markus Moenig on 10/3/21.
//

import MetalKit

class Core
{
    var view            : DMTKView!
    var device          : MTLDevice!

    var defaultLibrary  : MTLLibrary!

    var commandQueue    : MTLCommandQueue!

    var textureLoader   : MTKTextureLoader!

    var renderer        : Render!

    init()
    {
    }
    
    func setupView(_ view: DMTKView)
    {
        self.view = view
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            device = metalDevice
        } else {
            print("Cannot initialize Metal!")
        }
        
        view.core = self
        
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.preferredFramesPerSecond = 10;
        
        commandQueue = device.makeCommandQueue()

        textureLoader = MTKTextureLoader(device: device)
        view.platformInit()
        
        
        renderer = RenderMPS(self)
        renderer.setup()
        
        defaultLibrary = device.makeDefaultLibrary()
    }
    
    func draw()
    {
        renderer.render()
    }
    
    func viewSizeWillChange(size: SIMD2<Int>)
    {
        print("viewSizeWillChange", size)
        renderer.viewSizeWillChange(size: size)
    }
}
