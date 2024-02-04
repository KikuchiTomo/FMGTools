//
//  ViewController.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/02.
//

import Cocoa

enum ButtonTag: Int {
    case Ok = 100
    case Cancel = 200
}

protocol PressDataReceivingDelegate{
    func receiveDataInt(id: UInt32, time: UInt32, rawValue: UInt16, proced: Double)
}

class MainViewController: NSViewController{
    
    private var tmpMat: [[Double]] = []
    var tmpVec: [Double] = Array(repeating: 0.0,   count: 14)
    var revVec: [Bool]   = Array(repeating: false, count: 14)
    private let chn:Int = 5
    private let window_size: Int = 100
    
    private func isAllTrue(vec:[Bool]) -> Bool{
        var count = 0
        for i in 0..<vec.count{
            if(vec[i]){
                count+=1
            }
        }
        
        if count == vec.count{
            return true
        }else{
            return false
        }
    }
    
    private func updateData(id: Int, data: Double){
        if(!self.revVec[id]){
            self.tmpVec[id] = data
            self.revVec[id] = true
        }
        
        if self.isAllTrue(vec: self.revVec) {
            self.tmpMat.append(self.tmpVec)
            for i in 0..<self.chn{
                self.revVec[i] = false
            }
        }

        if self.tmpMat.count >= self.window_size{
            self.tmpMat.removeAll()
        }
    }
    
    var m: Double = 0.2
    
    private func convert(_ value: Double, _ maxLog: Double = 0.0, _ minLog: Double = -10) -> Double{
        if m < value && value < 1.0{
            m = min(value, 1.0)
            print(m)
        }
        
        let v0 = value / m
        return abs(v0 - 1.0)
    }
    
    private var receiveDataInt = {(id: UInt32, time: UInt32, rawValue: UInt16, proced: Double, view: MainViewController) -> Void in
        DispatchQueue.main.async {
            if(id < 5){
                let proc: Float = Float(view.convert(proced))
                view.lineGraphView.addPoint(point: proc, index: Int(id))
                view.heatMapView.setData(point: Float32(rawValue)/1024.0, index: Int(id))
            }
        }
    }
    
    private var mesSec: Float = -1
    private var setNum: Int = 0
    private var mesNum: Int = 0
    private var isRecording: Bool = false
    
    public var window: NSWindow?
    private var configWindow: NSWindow?
    
    private var recordButton: FlatButton = FlatButton()
    private var configButton: FlatButton = FlatButton()
    private var exitButton: FlatButton = FlatButton()
    
    private var graphView: NSView    = NSView()
    private var lineGraphView: LineGraph = LineGraph()
    private var lineICAGraphView: LineICAGraph = LineICAGraph()
    private var heatMapView: HeatMapView = HeatMapView()
    
    private var mainView: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))

    private var operationPopUpButton: NSPopUpButton = NSPopUpButton()
    private var operationLabel: NSLabel = NSLabel()
    
    private var personName: NSTextField = NSTextField()
    private var personNameLabel: NSLabel = NSLabel()
    
    private var countField: NSTextField = NSTextField()
    private var countLabel: NSLabel = NSLabel()
    
    private var setField: NSTextField = NSTextField()
    private var setLabel: NSLabel = NSLabel()
    
    private var secLabel: NSLabel = NSLabel()
    private var secPopUpButton: NSPopUpButton = NSPopUpButton()
        
    private lazy var fcField: NSTextField = generateFcField()
    private lazy var fcButton: FlatButton = generateButton()
    
    private var timerLabel: NSLabel = NSLabel()
    private lazy var fingerButtons: [FlatButton] = generateButtons()
    
    private var graphColors: [NSColor] = []
    private var imageView: NSImageView = NSImageView()
    
    func generateFcField() -> NSTextField{
        let view = NSTextField();
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholderString = "40"
        view.stringValue = "40"
        view.alignment = .center
        return view
    }
    
    func generateButton() -> FlatButton{
        let view = FlatButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.title = "適用"
        return view
    }
    
    func layoutFcUIs(){
        view.addSubview(fcField)
        view.addSubview(fcButton)
        
        NSLayoutConstraint.activate([
            fcField.topAnchor.constraint(equalTo: fingerButtons[0].bottomAnchor, constant: 10),
            fcField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
            fcField.widthAnchor.constraint(equalTo: configButton.widthAnchor, multiplier: 0.8, constant: -10),
            fcField.heightAnchor.constraint(equalToConstant: 30),
            fcButton.topAnchor.constraint(equalTo: fcField.topAnchor),
            fcButton.widthAnchor.constraint(equalTo:  configButton.widthAnchor, multiplier: 0.2, constant: 10),
            fcButton.heightAnchor.constraint(equalToConstant: 30),
            fcButton.leftAnchor.constraint(equalTo: fcField.rightAnchor, constant: 10)
        ])
        
        fcButton.action = #selector(viewDidClickFcButton(_:))
        fcButton.target = self
    }
    
    @objc func viewDidClickFcButton(_ sender: FlatButton){
        if let fc = Double(fcField.stringValue){
            SerialIntaractor.shared.setCutoff(fc: fc)
        }
    }
    
    func generateButtons() -> [FlatButton]{
        var views: [FlatButton] = []
        let labels = ["親指", "人差指", "中指", "薬指", "小指", "各指"]
        for label in labels {
            let view = FlatButton()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.title = label
            views.append(view)
        }
        return views
    }
    
    func updateButtons(){
        for fingerButton in fingerButtons {
            fingerButton.buttonColor = .gray
        }
        
        if imageAllFinger{
            fingerButtons[5].buttonColor = .red
        }else{
            fingerButtons[imageSelectedFinger-1].buttonColor = .red
        }
        
        for fingerButton in fingerButtons {
            fingerButton.needsDisplay = true
        }
    }
    
    private var startSec: Date = Date()
    
    private var images: [NSImage] = [
        NSImage(named: .m0)!,
        NSImage(named: .m1)!,
        NSImage(named: .m2)!,
        NSImage(named: .m3)!,
        NSImage(named: .m4)!,
        NSImage(named: .m5)!,
    ]
    
    override func loadView() {
        mainView.wantsLayer = false
        self.view = mainView
        self.view.wantsLayer = false
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initConfigWindow()
        
        graphColors.append(NSColor.rgba(red: 255, green: 0, blue: 0, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 0, green: 255, blue: 0, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 0, green: 0, blue: 255, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 0, green: 0, blue: 0,   alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 255, green: 0, blue: 255, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 0, green: 255, blue: 255, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 255, green: 128, blue: 0, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 128, green: 128, blue: 0, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 0, green: 128, blue: 128, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 128, green: 0, blue: 128, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 45, green: 0, blue: 128, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 128, green: 128, blue: 64, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 128, green: 128, blue: 255, alpha: 0.8))
        graphColors.append(NSColor.rgba(red: 151, green: 66, blue: 85, alpha: 0.8))
        
        
        view.addSubview(graphView)
        graphView.addSubview(lineGraphView)
        graphView.addSubview(heatMapView)
        // graphView.addSubview(lineICAGraphView)
        
        view.addSubview(recordButton)
        view.addSubview(configButton)
        view.addSubview(exitButton)
        view.addSubview(operationPopUpButton)
        view.addSubview(operationLabel)
        view.addSubview(personName)
        view.addSubview(personNameLabel)
        view.addSubview(countField)
        view.addSubview(countLabel)
        view.addSubview(setField)
        view.addSubview(setLabel)
        view.addSubview(secLabel)
        view.addSubview(secPopUpButton)
        view.addSubview(timerLabel)
        view.addSubview(imageView)
        
        let config = ConfigManager.shared.getConfig()
        heatMapView.setToggle(config.ena_sensor)
        for i in 0..<config.ena_sensor.count{
            lineGraphView.setToggle(index: i, enabled: config.ena_sensor[i])
        }
        
        layoutGraphView()
        layoutLineGraphView()
        // layoutLineICAGraphView()
        layoutHeatMapView()
        
        layoutRecordButton()
        layoutConfigButton()
        layoutExitButton()
        layoutOperationPopUpButton()
        layoutPersonTextField()
        layoutCountField()
        layoutSetField()
        layoutSecLabels()
        layoutTimerLabel()
        layoutImageView()
        layoutFingerView()
        layoutFcUIs()
        
        updateButtons()
        setProperButtonTitle()
        
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(lineGraphTimer), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timer), userInfo: nil, repeats: true)
        
        configButton.target = self
        configButton.action = #selector(viewDidPushConfigPresentButton)
        
        exitButton.target = self
        exitButton.action = #selector(viewDidPushExitButton)
        
        recordButton.target = self
        recordButton.action = #selector(viewDidPushDataStoreStartButton)
        
        
        let portName = ConfigManager.shared.getConfig().port_name
        SerialIntaractor.shared.view = self
        SerialIntaractor.shared.receiveDataInt = self.receiveDataInt
        SerialIntaractor.shared.setPortName(portName: portName)
        SerialIntaractor.shared.setStart()
        
        SerialIntaractor.shared.onWillStopRecByTimer = { () -> Void in
            DispatchQueue.main.async {
                print("Stop")
                self.viewDidPushDataStoreStartButton()
            }
        }
        
        //let v0 = ConfigViewController()
        //v0.prevView = self
        //v0.applySettings()
        
    }
   
    @objc private func timer(){
        if(isRecording){
            let timeInterval = Date().timeIntervalSince(startSec)
            let time = Int(timeInterval)

            let m = time / 60 % 60
            let s = time % 60
            let ms = Int(timeInterval * 100) % 100
            self.timerLabel.text = String(format: "%02d:%02d:%02d", m, s, ms)
            self.setProperImage(time: timeInterval)
        }else{
            self.timerLabel.text = "00:00:00"
        }
    }
    
    private func layoutPersonTextField(){
        personName.translatesAutoresizingMaskIntoConstraints = false
        personNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        personName.topAnchor.constraint(equalTo: operationLabel.bottomAnchor, constant: -10).isActive = true
        personName.rightAnchor.constraint(equalTo: configButton.rightAnchor).isActive = true
        personName.widthAnchor.constraint(equalTo: configButton.widthAnchor, multiplier: 0.65).isActive = true
        personName.heightAnchor.constraint(equalToConstant: 23).isActive = true
        personNameLabel.alignment = .center
        
        personNameLabel.centerYAnchor.constraint(equalTo: personName.centerYAnchor, constant: 2).isActive = true
        personNameLabel.leftAnchor.constraint(equalTo: configButton.leftAnchor, constant: 5).isActive = true
        personNameLabel.heightAnchor.constraint(equalToConstant: 23).isActive = true
        personNameLabel.widthAnchor.constraint(equalTo: configButton.widthAnchor, multiplier: 0.3).isActive = true
        personName.placeholderString = "PersonName"
        personName.stringValue = ConfigManager.shared.getConfig().persons[0].name
        personNameLabel.text = "被験者コード"
    }
        
    private func layoutOperationPopUpButton(){
        operationPopUpButton.translatesAutoresizingMaskIntoConstraints = false
        operationPopUpButton.topAnchor.constraint(equalTo: configButton.bottomAnchor, constant: 0).isActive = true
        operationPopUpButton.rightAnchor.constraint(equalTo: configButton.rightAnchor, constant: 0).isActive = true
        operationPopUpButton.widthAnchor.constraint(equalTo: configButton.widthAnchor, multiplier: 0.65).isActive = true
        operationPopUpButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        operationLabel.translatesAutoresizingMaskIntoConstraints = false
        operationLabel.leftAnchor.constraint(equalTo: configButton.leftAnchor, constant: 5).isActive = true
        operationLabel.centerYAnchor.constraint(equalTo: operationPopUpButton.centerYAnchor, constant: 12).isActive = true
        operationLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        operationLabel.widthAnchor.constraint(equalTo: configButton.widthAnchor, multiplier: 0.3).isActive = true
        operationLabel.text = "測定中の動作"
        
        let actions = ConfigManager.shared.getConfig().actions
        for i in 0..<actions.count{
            operationPopUpButton.addItem(withTitle: actions[i].name)
        }
    }
    
    private func layoutCountField(){
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countField.translatesAutoresizingMaskIntoConstraints = false
        
        countLabel.topAnchor.constraint(equalTo: personName.bottomAnchor, constant: 10).isActive = true
        countLabel.leftAnchor.constraint(equalTo: configButton.leftAnchor, constant: 0).isActive = true
        countLabel.rightAnchor.constraint(equalTo: configButton.rightAnchor, constant: 0).isActive = true
        countLabel.heightAnchor.constraint(equalToConstant: 23).isActive = true
        countLabel.text = "セット回数 (データセット)"
        countLabel.alignment = .center
        countField.alignment = .center
        countField.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 0).isActive = true
        countField.leftAnchor.constraint(equalTo: configButton.leftAnchor, constant: 0).isActive = true
        countField.rightAnchor.constraint(equalTo: configButton.rightAnchor, constant: 0).isActive = true
        countField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        countField.font = .monospacedSystemFont(ofSize: 20, weight: .bold)
        countField.bezelStyle = .roundedBezel
        countField.stringValue = String(setNum)
        countField.sizeToFit()
        countField.isHighlighted = false
    }
    
    private func layoutSetField(){
        setLabel.translatesAutoresizingMaskIntoConstraints = false
        setField.translatesAutoresizingMaskIntoConstraints = false
        
        setLabel.topAnchor.constraint(equalTo: countField.bottomAnchor, constant: 10).isActive = true
        setLabel.leftAnchor.constraint(equalTo: configButton.leftAnchor, constant: 0).isActive = true
        setLabel.rightAnchor.constraint(equalTo: configButton.rightAnchor, constant: 0).isActive = true
        setLabel.heightAnchor.constraint(equalToConstant: 23).isActive = true
        setLabel.text = "測定回数"
        setLabel.alignment = .center
        setField.alignment = .center
        setField.topAnchor.constraint(equalTo: setLabel.bottomAnchor, constant: 0).isActive = true
        setField.leftAnchor.constraint(equalTo: configButton.leftAnchor, constant: 0).isActive = true
        setField.rightAnchor.constraint(equalTo: configButton.rightAnchor, constant: 0).isActive = true
        setField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        setField.font = .monospacedSystemFont(ofSize: 20, weight: .bold)
        setField.bezelStyle = .roundedBezel
        setField.stringValue = String(mesNum)
        setField.sizeToFit()
        setField.isHighlighted = false
    }
    
    private var x: [Float] = [0.0, 0.0]
    
    @objc private func lineGraphTimer(){
        lineGraphView.needsDisplay = true
        heatMapView.needsDisplay = true
        // lineICAGraphView.needsDisplay = true
    }
    
    private func setProperButtonTitle(){
        if(isRecording){
            recordButton.title = "記録終了"
            recordButton.buttonColor = .systemRed
            recordButton.onClickColor = .systemOrange
        }else{
            recordButton.title = "記録開始"
            recordButton.buttonColor = .systemBlue
            recordButton.onClickColor = .systemCyan
        }
        
        exitButton.title   = "終了"
        configButton.title = "設定を開く"
        
        recordButton.needsDisplay = true
        exitButton.needsDisplay = true
        configButton.needsDisplay = true
    }
    
    private func layoutGraphView(){
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        graphView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        graphView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        graphView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
    }

    private func layoutLineGraphView(){
        lineGraphView.translatesAutoresizingMaskIntoConstraints = false
        lineGraphView.rightAnchor.constraint(equalTo: graphView.rightAnchor, constant: -5).isActive = true
        lineGraphView.leftAnchor.constraint(equalTo: graphView.leftAnchor, constant: 5).isActive = true
        
        lineGraphView.topAnchor.constraint(equalTo: graphView.topAnchor, constant: 5).isActive = true
        lineGraphView.heightAnchor.constraint(equalTo: graphView.heightAnchor, multiplier: 0.5, constant: -20).isActive = true
        lineGraphView.wantsLayer = false
        
        
        for i in 0..<chn{
            _ = lineGraphView.addGraph(title: "ADC" + String(i) as NSString, color: graphColors[i])
        }
        
        for i in 0..<chn{
            for _ in 0..<lineGraphView.samples{
                lineGraphView.addPoint(point: 0.5, index: i)
            }
        }
        
        lineGraphView.needsDisplay = true
    }
    
    private func layoutHeatMapView(){
        heatMapView.translatesAutoresizingMaskIntoConstraints = false
        heatMapView.rightAnchor.constraint(equalTo: graphView.rightAnchor, constant: -5).isActive = true
        heatMapView.leftAnchor.constraint(equalTo: graphView.leftAnchor, constant: 5).isActive = true
        heatMapView.bottomAnchor.constraint(equalTo: graphView.bottomAnchor, constant: -5).isActive = true
        heatMapView.topAnchor.constraint(equalTo: lineGraphView.bottomAnchor, constant: 2.5).isActive = true
        heatMapView.wantsLayer = false
        heatMapView.needsDisplay = true
    }
    
    private func layoutRecordButton(){
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        recordButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2, constant: -20).isActive = true
        recordButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
    }
    
    private func layoutConfigButton(){
        configButton.translatesAutoresizingMaskIntoConstraints = false
        configButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 10).isActive = true
        configButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        configButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2, constant: -20).isActive = true
        configButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
    }
    
    private func layoutExitButton(){
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        exitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2, constant: -20).isActive = true
        exitButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        exitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        
        exitButton.buttonColor  = NSColor.rgba(red: 255, green: 59, blue: 48, alpha: 1.0)
        exitButton.onClickColor = NSColor.rgba(red: 255, green: 69, blue: 58, alpha: 1.0)
        }
    
    override var representedObject: Any? {
        didSet {
        }
    }

    private func layoutSecLabels(){
        secLabel.translatesAutoresizingMaskIntoConstraints = false
        secPopUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        secPopUpButton.topAnchor.constraint(equalTo: setField.bottomAnchor, constant: 0).isActive = true
        secPopUpButton.rightAnchor.constraint(equalTo: configButton.rightAnchor, constant: 0).isActive = true
        secPopUpButton.widthAnchor.constraint(equalTo: configButton.widthAnchor, multiplier: 0.65).isActive = true
        secPopUpButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
                
        secLabel.alignment = .center
        secLabel.leftAnchor.constraint(equalTo: configButton.leftAnchor, constant: 5).isActive = true
        secLabel.centerYAnchor.constraint(equalTo: secPopUpButton.centerYAnchor, constant: 12).isActive = true
        secLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        secLabel.widthAnchor.constraint(equalTo: configButton.widthAnchor, multiplier: 0.3).isActive = true
        secLabel.text = "測定秒数"
        
        secPopUpButton.addItems(withTitles: ["秒数指定なし", "5", "10", "12", "14", "16", "45", "70"])
        secPopUpButton.target = self
        secPopUpButton.action = #selector(viewDidChangeSecPopUpButton)
    }
    
    private func layoutTimerLabel(){
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.topAnchor.constraint(equalTo: secPopUpButton.bottomAnchor, constant: 6).isActive = true
        timerLabel.widthAnchor.constraint(equalTo: recordButton.widthAnchor).isActive = true
        timerLabel.heightAnchor.constraint(equalTo: recordButton.heightAnchor).isActive = true
        timerLabel.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor).isActive = true
        
        timerLabel.text = "00:00:00"
        
        timerLabel.textColor = .white
        timerLabel.alignment = .center
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 30.0, weight: .regular)
    }
    
    //
    // 12 13 14|15 16 17|18 19 20|
    private var imageFlag = false
    private var imageFinger = 0
    private var prevImageTime = 0.0
    
    private var imageAllFinger: Bool = true
    private var imageSelectedFinger: Int = 1
    
    private func setProperImage(time: Double){
        let offset_time: Double = 5.0
        if(time <= offset_time){
            imageFlag = false
            imageFinger = 0
            prevImageTime = 0.0
            imageView.image = self.images[0]
        }else{
            let tmp_time = time - offset_time
            
            if(abs(prevImageTime - tmp_time) > 4.0 ){
                imageFlag = false
                prevImageTime = tmp_time
            }else if(abs(prevImageTime - tmp_time) < 2.0 && !imageFlag){
                imageFlag = true
                imageFinger += 1
            }
            
            if(abs(prevImageTime - tmp_time) <= 4.0 && abs(prevImageTime - tmp_time) >= 2.0){
                imageFlag = false
            }

            if(imageFlag){
                if(imageFinger < 1){
                    imageFinger = 1
                }

                if(imageFinger > 5){
                    imageFinger = 1
                }

                imageView.image = (imageAllFinger) ? self.images[imageFinger] : self.images[imageSelectedFinger] // images[imageFinger]
            }else{
                imageView.image = self.images[0]
            }
        }
        imageView.needsDisplay = true
    }
    
    private func layoutImageView(){
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 6).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor).isActive = true
        imageView.image = self.images[0]
        imageView.needsDisplay = true
    }
    
    func layoutFingerView(){
        for fingerButton in fingerButtons {
            self.view.addSubview(fingerButton)
            fingerButton.action = #selector(actionFingerSelect(_:))
            fingerButton.target = self
        }
       
        NSLayoutConstraint.activate([
            fingerButtons[0].topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            fingerButtons[0].heightAnchor.constraint(equalToConstant: 30),
            fingerButtons[0].widthAnchor.constraint(equalToConstant: 30),
            fingerButtons[0].leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10)
        ])
        
        for i in 1..<6{
            if i==1{
                NSLayoutConstraint.activate([
                    fingerButtons[i].topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
                    fingerButtons[i].heightAnchor.constraint(equalToConstant: 30),
                    fingerButtons[i].widthAnchor.constraint(equalToConstant: 45),
                    fingerButtons[i].leftAnchor.constraint(equalTo: fingerButtons[i-1].rightAnchor, constant: 5)
                ])
            }else{
                NSLayoutConstraint.activate([
                    fingerButtons[i].topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
                    fingerButtons[i].heightAnchor.constraint(equalToConstant: 30),
                    fingerButtons[i].widthAnchor.constraint(equalToConstant: 35),
                    fingerButtons[i].leftAnchor.constraint(equalTo: fingerButtons[i-1].rightAnchor, constant: 5)
                ])
            }
        }
    }
    
    @objc func actionFingerSelect(_ sender: FlatButton){
        for button in fingerButtons.enumerated() {
            if button.element.title == sender.title{
                if button.offset == (fingerButtons.count-1){
                    imageAllFinger = true
                }else{
                    imageAllFinger = false
                    imageSelectedFinger = button.offset + 1
                }
                break
            }
        }
        updateButtons()
    }
    
    private func initConfigWindow(){
        let windowSize = NSSize(width: 1000/3, height: 600)
        let screenSize = NSScreen.main?.frame.size ?? .zero
        let rect = NSMakeRect(screenSize.width/2 - windowSize.width/2, screenSize.height/2 - windowSize.height/2, windowSize.width, windowSize.height)
        self.configWindow = NSWindow(contentRect: rect, styleMask: [.closable, .titled], backing: .buffered, defer: false)
        self.configWindow?.title = "設定"
        self.configWindow?.isReleasedWhenClosed = false
    }
    
    public func updateActionPopUpButton(){
        operationPopUpButton.removeAllItems()
        let actions = ConfigManager.shared.getConfig().actions
        for i in 0..<actions.count{
            operationPopUpButton.addItem(withTitle: actions[i].name)
        }
    }
    
    public func updateGraphViewShows(){
        let enables = ConfigManager.shared.getConfig().ena_sensor        
        for i in 0..<enables.count{
            self.lineGraphView.setToggle(index: i, enabled: enables[i])
        }
        self.heatMapView.setToggle(enables)
    }
        
    @objc func viewDidChangeSecPopUpButton(){
        let text: String = self.secPopUpButton.titleOfSelectedItem ?? "秒数指定なし"
                
        if(text == "秒数指定なし"){
            self.mesSec = -1.0
        }else{
            self.mesSec = Float(text) ?? -1
        }
        
        print(self.mesSec)
        SerialIntaractor.shared.setTime(time: self.mesSec)
    }
    
    @objc func viewDidPushConfigPresentButton(){
              
        let view = ConfigViewController()
        view.window = window
        view.prevView = self
        
        configWindow?.contentViewController = view
        configWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func viewDidPushExitButton(){
        let alert = NSAlert()
        
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = "ソフトウェアを閉じますか？"
        alert.informativeText = "保存されていない変更内容は破棄されます"
        alert.icon = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: "")!
        
        let ok = alert.addButton(withTitle: "Ok")
        ok.image = NSImage(named: NSImage.actionTemplateName)
        ok.imagePosition = NSControl.ImagePosition.imageLeft
        ok.tag = ButtonTag.Ok.rawValue
        
        let cancel = alert.addButton(withTitle: "Cancel")
        cancel.tag = ButtonTag.Cancel.rawValue
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { response in
            switch response.rawValue
            {
            case ButtonTag.Ok.rawValue:
                SerialIntaractor.shared.setEnd()
                NSApplication.shared.terminate(self)
                break
            case ButtonTag.Cancel.rawValue:
                print("Cancel")
                break
            default:
                break
            }
        })
        
       
    }
    
    @objc func viewDidPushDataStoreStartButton(){       

        if(isRecording){          
            SerialIntaractor.shared.stopRecording()
            startSec = Date()          
            self.mesNum = (Int(self.setField.stringValue) ?? 0) + 1
            self.setField.stringValue = String(self.mesNum)
            self.setField.needsDisplay = true
            isRecording = false
        }else{
            startSec = Date()
            let tmpMesNum = Int(self.setField.stringValue) ?? 0
          
            
            let name:String = self.personName.stringValue
            let acti:String = self.operationPopUpButton.titleOfSelectedItem ?? "undefined"
            let path:String = ConfigManager.shared.getConfig().save_path
            
            self.setNum = Int(self.countField.stringValue) ?? 0
            self.mesNum = Int(self.setField.stringValue) ?? 0
            
            let date = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            let currentTime = df.string(from: date)
            
            let fpath:String =  path + "/" + String(setNum) + "_" + String(mesNum) + "_" + name + "_" + acti + "_" + currentTime + ".csv"
            let full_path:String = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(fpath).path
            print("File Name:", fpath.split(separator: "/")[fpath.split(separator: "/").count - 1], ".csv")
            
            SerialIntaractor.shared.startRecording(filePath: full_path, isFloat: true)
            isRecording = true
        }
        
        setProperButtonTitle()
    }

}
