//
//  HistogramView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/15.
//

import UIKit
import Accelerate

struct HistogramLevels {
    var red: [UInt]
    var green: [UInt]
    var blue: [UInt]
    var alpha: [UInt]
}

class HistogramView: UIView {
    
    private var histogram: HistogramLevels? {
        didSet {
            setNeedsDisplay()
        }
    }
 
    
    private let red = UIColor.systemRed.withAlphaComponent(0.6)
    private let green = UIColor.systemGreen.withAlphaComponent(0.8)
    private let blue = UIColor.systemBlue.withAlphaComponent(0.8)
    private let white = UIColor.white
    
    convenience init(histogram: HistogramLevels) {
        self.init()
        self.histogram = histogram
        
    }
    
    private func setupUI() {
        if let histogram = histogram {
            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()
            // draw RGB histogram
            drawHistogram(channel: histogram.red, color: red, maxValue: histogram.red.max()!, location: self.bounds.size)
            drawHistogram(channel: histogram.green, color: green, maxValue: histogram.green.max()!, location: self.bounds.size)
            drawHistogram(channel: histogram.blue, color: blue, maxValue: histogram.blue.max()!, location: self.bounds.size)
            context?.restoreGState()
        }
    }
    
    public func setHistogramData(_ levels: HistogramLevels) {
        self.histogram = levels
    }
    
    private func drawHistogram(channel: [UInt], color: UIColor, maxValue: UInt, location: CGSize) {
        let path = UIBezierPath()
        color.setStroke()
        path.lineWidth = 3
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        for bin in 0..<channel.count {
            let newPoint = CGPoint(
                x: xForBin(bin, proxy: location),
                y: yForCount(channel[bin], proxy: location)
            )
            path.move(to: CGPoint(x: newPoint.x, y: location.height))
            path.addLine(to: newPoint)
        }
        path.stroke()
        
        func xForBin(_ bin: Int, proxy: CGSize) -> CGFloat {
            let widthOfBin = proxy.width / CGFloat(channel.count)
            return CGFloat(bin) * widthOfBin
        }

        func yForCount(_ count: UInt, proxy: CGSize) -> CGFloat {
            let heightOfLevel = proxy.height / CGFloat(maxValue)
            return proxy.height - CGFloat(count) * heightOfLevel
        }
    }
    
}
