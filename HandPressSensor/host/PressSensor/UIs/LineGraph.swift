//
//  LineGraph.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/02.
//

import Foundation
import Cocoa

class LineGraph: NSView{
    public var gridColor: NSColor = .black
    public var gridSampleX: Int = 128
    public var gridSampleY: Int = 128
    public var gridAxisColor: NSColor = NSColor.rgba(red: 128, green: 128, blue: 128, alpha: 0.8)
    public var backgroundColor: NSColor = .white
    public var samples: Int = 2048 // 256本
    private var graphNum:    Int        = 0
    private var graphColors: [NSColor]  = []
    private var graphTitles: [NSString] = []
    private var graphDatas:   [[Float]] = []
    
    private var xmin: Float = 0.0
    private var xmax: Float = 1.0
    private var ymax: Float = 1.0
    private var ymin: Float = 0.0
        
    private func clip(point: Float) -> Float{
        if(point > 1.0){
            return 1.0
        }
        
        if(point < 0.0){
            return 0.0
        }
        
        return point
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func updateLayer() {
        print("OK")
    }
    
    private func drawGrid(width: CGFloat, height: CGFloat, paddingX:CGFloat, paddingY:CGFloat){
        let path = NSBezierPath()
        path.lineWidth = 1.0
        gridColor.setStroke()
        path.move(to: NSPoint(x: paddingX, y: paddingY))
        path.line(to: NSPoint(x: width - paddingX,    y: paddingY))
        path.move(to: NSPoint(x: paddingX, y: paddingY))
        path.line(to: NSPoint(x: paddingX, y: height - paddingY))
        path.move(to: NSPoint(x: paddingX, y: (height / 2.0)))
        path.line(to: NSPoint(x: width - paddingX, y: (height / 2.0)))
        
        let sample = CGFloat(samples / gridSampleX)
        let diff   = width / sample;
        var tmpx: CGFloat = paddingX
        for _ in 0..<Int(samples / gridSampleX){
            tmpx += diff
            path.move(to: NSPoint(x: tmpx, y: paddingY))
            path.line(to: NSPoint(x: tmpx, y: paddingY + 10))
        }
        path.stroke()
        
        let grid = NSBezierPath()
        tmpx = paddingX
        gridAxisColor.setStroke()
        for _ in 0..<Int(samples / gridSampleX){
            tmpx += diff
            grid.move(to: NSPoint(x: tmpx, y: paddingY + 10))
            grid.line(to: NSPoint(x: tmpx, y: height - paddingX))
        }
        grid.stroke()
    }
    
    private var enabled: [Bool] = [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true]
    public func setToggle(index: Int, enabled: Bool){
        self.enabled[index] = enabled
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Fill Paths
        self.layer?.cornerRadius = 4
        self.layer?.masksToBounds = true
        
        self.backgroundColor.setFill()
        dirtyRect.fill()
        
        let origin_width: CGFloat  = CGFloat(self.frame.width)
        let origin_height: CGFloat = CGFloat(self.frame.height)
        
        let clearance_y: CGFloat = 30
        let clearance_x: CGFloat = 30
        
        drawGrid(width: origin_width, height: origin_height, paddingX: clearance_x, paddingY: clearance_y)
        
        let width: CGFloat  = CGFloat(self.frame.width)  - (clearance_y * 2.0)
        let height: CGFloat = CGFloat(self.frame.height) - (clearance_x * 2.0)
        
        for graphIndex in 0..<graphNum{
            if enabled[graphIndex]{
                let path = NSBezierPath()
                path.lineWidth = 1.0;
                self.graphColors[graphIndex].setStroke()
                
                path.move(to: NSPoint(x: clearance_x, y: height/2.0 + clearance_x))
                
                let sample = CGFloat(self.samples)
                let diff   = width / sample;
                var x: CGFloat = 0
                
                for index in 0..<self.graphDatas[graphIndex].count{
                    x += diff
                    let len = self.graphDatas[graphIndex].count - 1
                    let y = height - CGFloat(self.graphDatas[graphIndex][len - index]) * height
                    path.line(to:NSPoint(x: x + clearance_x, y: y + clearance_y))
                }
                path.stroke()
            }
        }
    }
    
    public func addGraph(title: NSString, color: NSColor) -> Int{
        graphTitles.append(title)
        graphColors.append(color)
        let graphData: [Float] = []
        graphDatas.append(graphData)
        graphNum += 1
        return graphNum
    }
    
    public func addPoint(point: Float, index: Int){
        let x: Float = clip(point: point)
        
        let len = self.graphDatas[index].count
        if(len >= samples){
            self.graphDatas[index].remove(at: 0)
        }
        self.graphDatas[index].append(x)
    }
}
