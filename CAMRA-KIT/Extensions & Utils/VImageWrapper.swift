//
//  ImageWrapper.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/15.
//

import Foundation
import UIKit
import Accelerate

enum WrappedImage {
    case original
    case processed
}

struct VImageWrapper {
    var uiImage: UIImage
    var processedImage: UIImage?
    let vNoFlags = vImage_Flags(kvImageNoFlags)

  init(uiImage: UIImage) {
    self.uiImage = uiImage
    if let buffer = createVImage(image: uiImage),
      let converted = convertToUIImage(buffer: buffer) {
        processedImage = converted
    }
  }

    func createVImage(image: UIImage) -> vImage_Buffer? {
        guard
            let cgImage = uiImage.cgImage,
            let imageBuffer = try? vImage_Buffer(cgImage: cgImage)
        else {
            return nil
        }
        return imageBuffer
    }

    func convertToUIImage(buffer: vImage_Buffer) -> UIImage? {
        guard
            let originalCgImage = uiImage.cgImage,
            let format = vImage_CGImageFormat(cgImage: originalCgImage),
            let cgImage = try? buffer.createCGImage(format: format)
        else {
            return nil
        }

        let image = UIImage(
            cgImage: cgImage,
            scale: 1.0,
            orientation: uiImage.imageOrientation)
        return image
    }

    mutating func equalizeHistogram() {
        guard
            let image = uiImage.cgImage,
            var imageBuffer = createVImage(image: uiImage),
            var destinationBuffer = try? vImage_Buffer(
                width: image.width,
                height: image.height,
                bitsPerPixel: UInt32(image.bitsPerPixel))
        else {
          print("Error creating image buffers.")
          processedImage = nil
          return
        }
        defer {
          imageBuffer.free()
          destinationBuffer.free()
        }

        let error = vImageEqualization_ARGB8888(&imageBuffer, &destinationBuffer, vNoFlags)

        guard error == kvImageNoError else {
          printVImageError(error: error)
          processedImage = nil
          return
        }
        processedImage = convertToUIImage(buffer: destinationBuffer)
    }

    mutating func reflectImage() {
        guard
          let image = uiImage.cgImage,
          var imageBuffer = createVImage(image: uiImage),
          var destinationBuffer = try? vImage_Buffer(
            width: image.width,
            height: image.height,
            bitsPerPixel: UInt32(image.bitsPerPixel))
        else {
          print("Error creating image buffers.")
          processedImage = nil
          return
        }
        defer {
          imageBuffer.free()
          destinationBuffer.free()
        }

        let error = vImageHorizontalReflect_ARGB8888(&imageBuffer, &destinationBuffer, vNoFlags)
        guard error == kvImageNoError else {
          printVImageError(error: error)
          processedImage = nil
          return
        }
        processedImage = convertToUIImage(buffer: destinationBuffer)
    }
    
    func resizeImage(scaleX: CGFloat, y: CGFloat) {
        guard let image = uiImage.cgImage,
              let format = vImage_CGImageFormat(cgImage: image),
              var sourceBuffer = createVImage(image: uiImage)
        else {
            return
        }
        
        let destinationHeight = CGFloat(sourceBuffer.height) * y
        let destinationWidth = CGFloat(sourceBuffer.width) * scaleX
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(destinationWidth),
                                                         height: Int(destinationHeight),
                                                         bitsPerPixel: UInt32(image.bitsPerPixel)) else {
                                                            return
        }
        
        
        
        defer {
            sourceBuffer.free()
            destinationBuffer.free()
        }
        
        let error = vImageScale_ARGB8888(&sourceBuffer,
                                     &destinationBuffer,
                                     nil,
                                     vImage_Flags(kvImageHighQualityResampling))
                
        guard error == kvImageNoError else {
            fatalError("Error in vImageScale_ARGB8888: \(error)")
        }
        
        let result = try? destinationBuffer.createCGImage(format: format)

        if let result = result {
            print("result: \(result.width) \(result.height)")
//            return UIImage(cgImage: result)
        } else {
//            return nil
        }
    }
    
    static public func getHistogram(_ cgImage: CGImage?) -> HistogramLevels? {
        guard
            let cgImage = cgImage,
            var imageBuffer = try? vImage_Buffer(cgImage: cgImage)
        else {
            return nil
        }
        defer {
            imageBuffer.free()
        }

        var redArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var greenArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var blueArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var alphaArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var error: vImage_Error = kvImageNoError
        

        redArray.withUnsafeMutableBufferPointer { rPointer in
            greenArray.withUnsafeMutableBufferPointer { gPointer in
                blueArray.withUnsafeMutableBufferPointer { bPointer in
                    alphaArray.withUnsafeMutableBufferPointer { aPointer in
                        var histogram = [
                            rPointer.baseAddress, gPointer.baseAddress,
                            bPointer.baseAddress, aPointer.baseAddress
                        ]
                        histogram.withUnsafeMutableBufferPointer { hPointer in
                            if let hBaseAddress = hPointer.baseAddress {
                                error = vImageHistogramCalculation_ARGB8888(&imageBuffer, hBaseAddress, vImage_Flags(kvImageNoFlags))
                            }
                        }
                    }
                }
            }
        }

        guard error == kvImageNoError else {
            return nil
        }
        let histogramData = HistogramLevels(
            red: redArray,
            green: greenArray,
            blue: blueArray,
            alpha: alphaArray
        )
        return histogramData
    }

    public func getHistogram(_ image: WrappedImage) -> HistogramLevels? {
        guard
            let cgImage = image == .original ? uiImage.cgImage : processedImage?.cgImage,
            var imageBuffer = try? vImage_Buffer(cgImage: cgImage)
        else {
            return nil
        }
        defer {
            imageBuffer.free()
        }

        var redArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var greenArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var blueArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var alphaArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var error: vImage_Error = kvImageNoError
        

        redArray.withUnsafeMutableBufferPointer { rPointer in
            greenArray.withUnsafeMutableBufferPointer { gPointer in
                blueArray.withUnsafeMutableBufferPointer { bPointer in
                    alphaArray.withUnsafeMutableBufferPointer { aPointer in
                        var histogram = [
                            rPointer.baseAddress, gPointer.baseAddress,
                            bPointer.baseAddress, aPointer.baseAddress
                        ]
                        histogram.withUnsafeMutableBufferPointer { hPointer in
                            if let hBaseAddress = hPointer.baseAddress {
                                error = vImageHistogramCalculation_ARGB8888(&imageBuffer, hBaseAddress, vNoFlags)
                            }
                        }
                    }
                }
            }
        }

        guard error == kvImageNoError else {
            printVImageError(error: error)
            return nil
        }
        let histogramData = HistogramLevels(
            red: redArray,
            green: greenArray,
            blue: blueArray,
            alpha: alphaArray
        )
        return histogramData
    }
    
    
}

extension VImageWrapper {
    func printVImageError(error: vImage_Error) {
        let errDescription = vImage.Error(vImageError: error).localizedDescription
        print("vImage Error: \(errDescription)")
    }
}
