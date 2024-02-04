//
//  HeatMapGraph.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/02.
//

import Foundation
import Cocoa

class HeatMapView: NSView{
    public var backgroundColor: NSColor = .white
    private var graph:        Int       = 0
    private var graphTitles: [NSString] = []
    private var graphDatas:   [Float] = []
    private var ena: [Bool] = [true, true, true, true, true, true, true, true, true, true, true, true, true, true]
    
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
        for _ in 0..<14{
            graphDatas.append(0.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func updateLayer() {
        print("OK")
    }
    
    func setToggle(_ ena: [Bool]){
        self.ena = ena
        if self.ena.count < 14{
            for _ in 0..<(14-self.ena.count){
                self.ena.append(true)
            }
        }
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
              
        let width: CGFloat  = CGFloat(self.frame.width)  - (clearance_y * 2.0)
        let height: CGFloat = CGFloat(self.frame.height) - (clearance_x * 2.0)
        
        let rect_w: CGFloat = width  / 7
        let rect_y: CGFloat = height / 2
        
        for j in 0..<2{
            var x: CGFloat = clearance_x
            for i in 0..<7{
                x += rect_w
                let path = NSBezierPath(rect: NSRect(x: x-rect_w, y: (rect_y * CGFloat(j))+clearance_y, width: rect_w, height: rect_y))
                if self.ena[(j*7) + i]{
                    NSColor.init(red: CGFloat(graphDatas[j*7 + i] / 128.0), green: CGFloat(graphDatas[j*7 + i]), blue: CGFloat(graphDatas[j*7 + i] / 128.0), alpha: 1.0).setFill()
                }else{
                    NSColor.black.setFill()
                }
                    path.fill()
                
            }
        }        
    }
       
    
    public func setData(point: Float, index: Int){
        var x: Float = clip(point: point)
        graphDatas[index] = x
    }
}
