//
//  main.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/02.
//

import Foundation
import Cocoa

let delegate = AppDelegate()

NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
