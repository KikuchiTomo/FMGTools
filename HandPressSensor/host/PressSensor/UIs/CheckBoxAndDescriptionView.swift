//
//  CheckBoxAndDescriptionView.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/06.
//

import Foundation
import Cocoa

class CheckBoxAndDescriptionView: NSView{
    
    // private let stack: NSStackView = NSStackView()
    private let label: NSTextField = NSTextField()
    private let checkBox: NSCheckBox = NSCheckBox()
    
    public var title: String {
        get{ return self.title }
        set{
            self.label.stringValue = newValue
            self.label.drawsBackground = false
            self.label.isBordered = false
            self.label.isEditable = false
            self.label.isSelectable = false
        }
    }
    
    public var isChecked: Bool{
        get{ return checkBox.isChecked }
        set{ checkBox.isChecked = newValue }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.label.font = NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular)
        self.title = "Chech Box Text"
        self.label.drawsBackground = false
        self.label.isBordered = false
        self.label.isEditable = false
        self.label.isSelectable = false
        
        label.translatesAutoresizingMaskIntoConstraints = false
        checkBox.translatesAutoresizingMaskIntoConstraints = false
    }
      
    public func setUp(){
        // self.addSubview(stack)
        self.addSubview(label)
        self.addSubview(checkBox)

        label.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: checkBox.leftAnchor).isActive = true
        checkBox.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        checkBox.widthAnchor.constraint(equalToConstant: 12).isActive = true
        checkBox.heightAnchor.constraint(equalToConstant: 12).isActive = true
        self.needsDisplay = true
        self.needsLayout = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
