//
//  ConfigViewController.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/06.
//

import Foundation
import Cocoa

class ConfigViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource{
    public var prevView: MainViewController!
    
    public var window: NSWindow?
    private var mainView:NSView = NSView(frame: NSRect(x: 0, y: 0, width: 1000/3, height: 800))

    private let titleFont: NSFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
    private var stackView: NSStackView = NSStackView()
    private var enableSensorSettingTitle: NSLabel = NSLabel()

    private var adcStackView: [NSStackView] = []
    private var enableSensorSettingViews: [NSButton] = []
    
    private var actionTableView: NSTableView = NSTableView()
    private var addActionTableButton: NSButton = NSButton()
    private var removeActionTableButton: NSButton = NSButton()
    
    private var actions: [Action] = []
    
    private var saveDirTextField: NSTextField = NSTextField()
    
    private var baudRatePopUpButton: NSPopUpButton = NSPopUpButton()
    private var serialPortNameField: NSTextField = NSTextField()
    
    private var applyButton: FlatButton = FlatButton()
    
    private let configManager: ConfigManager = ConfigManager.shared
    
  
    override func loadView() {
        mainView.wantsLayer = false
        self.view = mainView
        self.view.wantsLayer = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpStackView()
        layoutStackView()
        
        setUpEnableSensorSetting()
        setUpActionSetting()
        setUpSaveDirSetting()
        setUpSerialSetting()
        
        applyButton.title = "適用"
        stackView.addView(applyButton, in: .top)
        applyButton.target = self
        applyButton.action = #selector(applySettings)
                
    }
    
    override func viewDidLayout() {
        self.updateSetting()
    }
    
    func setUpStackView(){
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
    }
    
    func layoutStackView(){
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0, constant: -10).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
    }
    
    func setUpEnableSensorSetting(){
        stackView.orientation = .vertical
        stackView.alignment = .leading
//        stackView.distribution = .gravityAreas
        enableSensorSettingTitle.font = titleFont
        enableSensorSettingTitle.stringValue = "有効センサ設定"
        stackView.addView(enableSensorSettingTitle, in: .top)
        for i in 0..<2{
            self.adcStackView.append(NSStackView())
            self.adcStackView[i].alignment = .leading
            self.adcStackView[i].orientation = .horizontal
            self.adcStackView[i].distribution = .equalSpacing
            let label: NSLabel = NSLabel()
            label.stringValue = "ADC " + String(i)
            self.stackView.addView(label, in: .top)
            for j in 0..<7{
                let checkBox = NSButton()
                checkBox.title = String(format: "%02d", j+1) + ""
                checkBox.setButtonType(.switch)
                checkBox.state = .on
                self.enableSensorSettingViews.append(checkBox)
                self.adcStackView[i].addView(checkBox, in: .trailing)
            }
            self.stackView.addView(self.adcStackView[i], in: .top)
        }
    }
    
    func setUpActionSetting(){
        let label = NSLabel()
        label.text = "動作の定義"
        label.font = titleFont
        
        self.stackView.addView(label, in: .top)
        self.actionTableView.delegate = self
        self.actionTableView.dataSource = self
        
        let clmId = NSTableColumn()
        clmId.title = "ID"
        clmId.identifier = NSUserInterfaceItemIdentifier(rawValue: "id")
        self.actionTableView.addTableColumn(clmId)
        
        let clmName = NSTableColumn()
        clmName.title = "Action Name"
        clmName.identifier = NSUserInterfaceItemIdentifier(rawValue: "name")
        self.actionTableView.addTableColumn(clmName)
            

        self.actionTableView.identifier = NSUserInterfaceItemIdentifier(rawValue: "ActionTable")
        self.stackView.addView(actionTableView, in: .top)
        self.stackView.addView(addActionTableButton, in: .top)
        addActionTableButton.title    = "+   Add action define "
        addActionTableButton.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        addActionTableButton.target = self
        addActionTableButton.action = #selector(onClickAddActionTableButton)
        self.stackView.addView(removeActionTableButton, in: .top)
        removeActionTableButton.title = "- Remove action define"
        removeActionTableButton.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        removeActionTableButton.target = self
        removeActionTableButton.action  = #selector(onClickRemoveActionTableButton)
        self.actionTableView.scrollRowToVisible(0)
        self.actionTableView.isEnabled = true
    }
    
    func setUpSaveDirSetting(){
        let label = NSLabel()
        label.text = "保存先の設定"
        label.font = titleFont
        
                
        self.stackView.addView(label, in: .top)
        saveDirTextField.placeholderString = "Save directory path..."
        self.stackView.addView(saveDirTextField, in: .top)
    }
    
    func setUpSerialSetting(){
        let label = NSLabel()
        label.text = "シリアル通信の設定"
        label.font = titleFont
        
        self.stackView.addView(label, in: .top)
        self.stackView.addView(baudRatePopUpButton, in: .top)
        baudRatePopUpButton.addItems(withTitles: ["9600", "19200", "38400", "57600", "115200", "230400"])
        self.stackView.addView(serialPortNameField, in: .top)
        serialPortNameField.placeholderString = "PortName: /dev/tty.xxxxx-xxxxx-xxxxx"
        let label2 = NSLabel()
        label2.text = "※ シリアル通信の設定はアプリ再起動時に適用されます．"
        self.stackView.addView(label2, in: .top)
    }
    
    @objc func onClickAddActionTableButton(){
        var alert = NSAlert()
        alert.informativeText = "IDとアクション名(保存ファイル名やJSONファイルにタグ付け用と使用されます)"
        alert.messageText = "動作の定義を追加"
        alert.alertStyle = .informational
             
        //alert.accessoryView = formStackView;
        let formView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 24 * 2 + 5))
        let nameField = NSTextField(frame: NSRect(x:0,y: 0,width:  200,height: 24))
        let idField   = NSTextField(frame: NSRect(x:0,y: 24+4,width:  200,height: 24))
        nameField.placeholderString = "Action Name"
        idField.placeholderString   = "Action Id"
        formView.addSubview(idField)
        formView.addSubview(nameField)
        alert.accessoryView = formView
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let res = alert.runModal()
        
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            self.actions.append(Action(id: Int(idField.stringValue) ?? -1, name: nameField.stringValue))
            self.actionTableView.reloadData()
        }else if res == NSApplication.ModalResponse.alertSecondButtonReturn {
            
        }
    }
    
    @objc func onClickRemoveActionTableButton(){
        if(self.actionTableView.selectedRow >= 0){
            self.actions.remove(at: self.actionTableView.selectedRow)
            self.actionTableView.reloadData()
        }
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    // Table Delegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.actions.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        let columns = tableColumn?.identifier.rawValue
                        
        if columns == "name"{
            return self.actions[row].name
        }else if(columns == "id"){
            return self.actions[row].id
        }
        
        return ""
    }
    
    @objc func applySettings(){
        print("apply")
        let r_config: Config = self.configManager.getConfig()
        
        var ena: [Bool] = []
        print(enableSensorSettingViews.count)
        for i in 0..<self.enableSensorSettingViews.count{
            ena.append(self.enableSensorSettingViews[i].state == .on)
            print(self.enableSensorSettingViews[i].state == .on)
        }
        
        let w_config: Config = Config(
            port_name: self.serialPortNameField.stringValue,
            baud_rate: Int(self.baudRatePopUpButton.titleOfSelectedItem ?? "9600") ?? 9600,
            save_path: self.saveDirTextField.stringValue,
            config_path: r_config.config_path,
            actions: self.actions,
            persons: r_config.persons,
            ena_sensor: ena
        )
        
        self.configManager.setConfig(config: w_config)
        
        self.prevView.updateGraphViewShows()
        self.prevView.updateActionPopUpButton()
    }
    
    public func updateSetting(){
        var config: Config = configManager.getConfig()
        for i in 0..<enableSensorSettingViews.count{
            if config.ena_sensor.count < 14{
                for _ in 0..<(14-config.ena_sensor.count){
                    config.ena_sensor.append(true)
                }
            }
            if config.ena_sensor[i] {
                enableSensorSettingViews[i].state = .on
            }else{
                enableSensorSettingViews[i].state = .off
            }
            enableSensorSettingViews[i].needsDisplay = true
        }
        
        serialPortNameField.stringValue = config.port_name
        serialPortNameField.needsDisplay = true
        
        saveDirTextField.stringValue = config.save_path
        saveDirTextField.needsDisplay = true
        
        actions = config.actions
        actionTableView.reloadData()
        
        baudRatePopUpButton.selectItem(withTitle: String(config.baud_rate))
        baudRatePopUpButton.needsDisplay = true
    }
}
