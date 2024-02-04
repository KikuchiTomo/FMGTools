//
//  MyFlatButton.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/02.
//

import Foundation
import AppKit

extension NSColor {
    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> NSColor{
        return NSColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
}

public class FlatButton: NSButton {
 
    public var buttonColor:  NSColor = .systemBlue
    public var onClickColor: NSColor = NSColor.rgba(red: 0, green: 122, blue: 255, alpha: 1.0)
    public var textColor: NSColor = NSColor.white
    public var fontSize: CGFloat = NSFont.systemFontSize
    
    public override func resetCursorRects() {
           addCursorRect(bounds, cursor: .pointingHand)
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let rectanglePath = NSBezierPath(rect: NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
     
        var fillColor: NSColor
        var strokeColor: NSColor
        
        rectanglePath.fill()
        
        if self.isHighlighted {
            strokeColor = self.buttonColor
            fillColor = self.onClickColor
        } else {
            strokeColor = self.onClickColor
            fillColor = self.buttonColor
        }
               
        strokeColor.setStroke()
        rectanglePath.lineWidth = 5
        rectanglePath.stroke()
        self.layer?.cornerRadius = 4
        self.layer?.masksToBounds = true
        fillColor.setFill()
        rectanglePath.fill()
        bezelStyle = .shadowlessSquare
     
        let textRect = NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        let textTextContent = self.title
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        
        let textFontAttributes : [ NSAttributedString.Key : Any ] = [
            .font: NSFont(name: "Monaco", size: self.fontSize)!,
          .foregroundColor: textColor,
          .paragraphStyle: textStyle
        ]

        let textTextHeight: CGFloat = textTextContent.boundingRect(with: NSSize(width: textRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes).height
        let textTextRect: NSRect = NSRect(x: 0, y: -3 + ((textRect.height - textTextHeight) / 2), width: textRect.width, height: textTextHeight)
        NSGraphicsContext.saveGraphicsState()
        textTextContent.draw(in: textTextRect.offsetBy(dx: 0, dy: 3), withAttributes: textFontAttributes)
        NSGraphicsContext.restoreGraphicsState()
    }
}

