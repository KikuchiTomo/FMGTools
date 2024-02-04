//
//  NSLabel.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/06.
//

import Foundation
import Cocoa

class NSLabel: NSTextField{
    public var text: String{
        set{
            self.stringValue = newValue
        }
        get{
            return self.stringValue
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.drawsBackground = false
        self.isEditable = false
        self.isSelectable = false
        self.isBordered = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
