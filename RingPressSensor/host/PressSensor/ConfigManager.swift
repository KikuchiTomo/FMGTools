//
//  ConfigManager.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/06.
//

import Foundation

final class ConfigManager{
    public static let shared = ConfigManager()
    
    private let fileManager = FileManager.default
    private let defaultConfigFileName = ".kPressForHandConfig.conf.json"

    private init(){
       
    }
    
    public func updateConfig(config: Config){
        let url_check = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(defaultConfigFileName)        
        let exist = fileManager.fileExists(atPath: url_check.path)
        let jsonData: Data? = try? JSONEncoder().encode(config)

        if(exist){
            do{
                let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(defaultConfigFileName)
                
                do {
                    try jsonData?.write(to: url)
                } catch let error {
                    print("write e00", error)
                }
            }catch let error{
                print("weite e01", error)
            }
        }else{
           
            do{
                let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(defaultConfigFileName)
                                                               
                do {
                    try jsonData?.write(to: url)
                } catch let error {
                    print("write e10", error)
                }
                               
            }catch let error{
                print("write e11", error)
            }
        }
    }
    
    public func createConfigAndRead() -> Config?{
        let url_check = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(defaultConfigFileName)
        let exist = fileManager.fileExists(atPath: url_check.path)
        
        if(exist){
            let url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(defaultConfigFileName)
                      
            do {
                let jsonData = try Data(contentsOf: url)
                let readConfig = Config(json: jsonData)
                return readConfig
            } catch let error {
                 print("read", error)
            }
        }else{
            let stData: Config = prepareDefaultValue()
            let jsonData: Data? = try? JSONEncoder().encode(stData)

            do{
                let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(defaultConfigFileName)
                                                               
                do {
                    try jsonData?.write(to: url)
                } catch let error {
                    print("write e0", error)
                }
                
                return stData
            }catch let error{
                print("write e1", error)
            }
        }
        
        return nil
    }
    
    private func prepareDefaultValue() -> Config{
        let url_check = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        
        var conf:Config = Config(
            port_name: "/dev/tty.usbmodem1301",
            baud_rate: 115200,
            save_path: "kPressOutput",
            config_path: url_check.path + "/" + defaultConfigFileName,
            actions:
                [
                    Action(id: 0, name: "oya"),
                    Action(id: 1, name: "hitosasi"),
                    Action(id: 2, name: "naka"),
                    Action(id: 3, name: "kusuri"),
                    Action(id: 4, name: "koyubi"),
                    Action(id: 5, name: "all"),
                    Action(id: 6, name: "all_open"),
                ],
            persons: [
                Person(id: 0, age: 20, name: "KikuchiTomoo", weight: 62.0)
            ],
            ena_sensor: [true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,])
        
        return conf
    }
    
    private func checkAndCreateSaveDir(config: Config){
        let path = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(config.save_path)
        let exist = fileManager.fileExists(atPath: path.path)
        
        if(exist){
            
        }else{
            do{
                try fileManager.createDirectory(atPath: path.path, withIntermediateDirectories: true)
            }catch let error{
                print("create0", error)
            }
        }
    
        
    }
    
    public func getConfig() -> Config{
        guard let config = createConfigAndRead() else{
            return prepareDefaultValue()
        }
        
        checkAndCreateSaveDir(config: config)
        
        return config
    }
    
    public func setConfig(config: Config){
        updateConfig(config: config)
        checkAndCreateSaveDir(config: config)
    }
}
