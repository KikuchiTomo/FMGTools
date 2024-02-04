//
//  AppDelegate.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/02.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let windowSize = NSSize(width: 1000, height: 700)
        let screenSize = NSScreen.main?.frame.size ?? .zero
        let rect = NSMakeRect(screenSize.width/2 - windowSize.width/2, screenSize.height/2 - windowSize.height/2, windowSize.width, windowSize.height)
        window = NSWindow(contentRect: rect, styleMask: [.miniaturizable, .closable, .resizable, .titled], backing: .buffered, defer: false)
        window?.title = "圧力センサ"
        
        let view = MainViewController()
        view.window = window
        
        window?.contentViewController = view
        window?.makeKeyAndOrderFront(nil)                
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

