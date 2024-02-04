//
//  SerialPresenter.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/05.
//

import Foundation

final class SerialIntaractor: SerialObjcDelegate{
    static public let shared = SerialIntaractor();
    private let session: SerialController = SerialController.sharedInstance()
    private let config: ConfigManager = ConfigManager.shared
   
    public var receiveDataInt: ((UInt32, UInt32, UInt16, Double, MainViewController) -> Void)!
    public var onWillStopRecByTimer: (() -> Void)!
    public var view:MainViewController!
    
    private init(){        
    }
    
    private func makeCString(from str: String) -> UnsafeMutablePointer<Int8> {
        let count = str.utf8CString.count
        let result: UnsafeMutableBufferPointer<Int8> = UnsafeMutableBufferPointer<Int8>.allocate(capacity: count)
        // func initialize<S>(from: S) -> (S.Iterator, UnsafeMutableBufferPointer<Element>.Index)
        _ = result.initialize(from: str.utf8CString)
        return result.baseAddress!
    }
    
    public func startRecording(filePath: String, isFloat: Bool){
        let st = makeCString(from: filePath)
        session.startRecording(st, isFloat: isFloat)
    }
    
    public func stopRecording(){
        session.endRecording()
    }
    
    public struct SensorData{
        let id:  Int16
        let time_int32:   Int32
        let rawd_int32:   Int16
        let time_float32: Float32
        let rawd_float32: Float32
    }
            
    public func setCutoff(fc: Double){
        session.setCutoff(fc)
    }
    
    public func setPortName(portName: String){
        session.setSerialPortName(makeCString(from: portName))
    }
    
    public func setStart(){
        session.delegate = self
        session.startSerial()
    }
    
    public func onRecvData(withId id: UInt32, time: UInt32, raw: UInt16, proced:Double) {
        if receiveDataInt != nil{
            receiveDataInt(id, time, raw, proced, view)
        }
    }
    
    public func onWillStopByTimer(){
        if onWillStopRecByTimer != nil{
            onWillStopRecByTimer()
        }
    }
    
    public func setEnd(){
        session.endSerial()
    }
    
    public func setTime(time: Float32){
        session.setRecordingTime(time)
    }
}
