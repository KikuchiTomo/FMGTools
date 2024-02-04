//
//  CheckBox.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/06.
//

import Foundation
import Cocoa

class NSCheckBox: NSButton{
    public var backgroundColor: NSColor = .systemBlue
    public var checkBoxColor: NSColor = .white
    public var onClickBackgroundColor: NSColor = .systemCyan
    public var onClickCheckBoxColor: NSColor = .systemRed
    
    private let checkedImage: NSImage = NSImage(systemSymbolName: "checkmark.square.fill", accessibilityDescription: "")!
    private let nonCheckedImage: NSImage = NSImage(systemSymbolName: "checkmark.square", accessibilityDescription: "")!
    
    public var isChecked: Bool {
        get { return state == NSControl.StateValue.on }
        set { state = newValue ? NSControl.StateValue.on : NSControl.StateValue.off }
    }
    
    public override func resetCursorRects() {
           addCursorRect(bounds, cursor: .pointingHand)
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let pathRect = NSBezierPath(rect: NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        pathRect.fill()
        
        var beforeBackGroundColor: NSColor
        var afterBackGroudColor: NSColor
        
        if(self.isHighlighted){
            beforeBackGroundColor = self.backgroundColor
            afterBackGroudColor   = self.onClickBackgroundColor
        }else{
            beforeBackGroundColor = self.onClickBackgroundColor
            afterBackGroudColor   = self.backgroundColor
        }
        
        beforeBackGroundColor.setStroke()
        pathRect.lineWidth = 2
        pathRect.stroke()
        self.layer?.cornerRadius = 2
        self.layer?.masksToBounds = true
        afterBackGroudColor.setFill()
        pathRect.fill()
        bezelStyle = .shadowlessSquare
        
        var checkBoxRect = NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)

        self.nonCheckedImage.backgroundColor = .systemRed
        self.checkedImage.backgroundColor = .systemGreen
        
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext.current
        
        var affine: CGAffineTransform = CGAffineTransform()
        // CGAffineTransformIdentity();
        affine.d = -1.0;
        affine.ty = 20 + 20 + 12;
        
        // context?.cgContext.concatenate(affine)
        
        if(self.isChecked){
            let checkedCgImage = self.checkedImage.cgImage(forProposedRect: &checkBoxRect, context: context, hints: nil)!
            context?.cgContext.draw(checkedCgImage, in: checkBoxRect)
        }else{
            let nonCheckedCgImage = self.nonCheckedImage.cgImage(forProposedRect: &checkBoxRect, context: context, hints: nil)!
            context?.cgContext.draw(nonCheckedCgImage, in: checkBoxRect)
        }
                                
        NSGraphicsContext.restoreGraphicsState()
    }
}
