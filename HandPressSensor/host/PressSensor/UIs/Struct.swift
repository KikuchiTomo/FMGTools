//
//  ActionStruct.swift
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/06.
//

import Foundation

struct Action: Codable{
    var id: Int = 0
    var name: String = ""
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
    }
}

struct Person: Codable{
    var id: Int
    var age: Int
    var name: String
    var weight: Float
    
    init(id: Int, age: Int, name: String, weight: Float) {
        self.id = id
        self.age = age
        self.name = name
        self.weight = weight
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.age = try container.decode(Int.self, forKey: .age)
        self.name = try container.decode(String.self, forKey: .name)
        self.weight = try container.decode(Float.self, forKey: .weight)
    }
}

struct Config: Codable{
    var port_name: String
    var baud_rate: Int
    
    var save_path: String
    var config_path: String

    var actions: [Action]
    var persons: [Person]
    
    var ena_sensor: [Bool]
    
    init(port_name: String, baud_rate: Int, save_path: String, config_path: String, actions: [Action], persons: [Person], ena_sensor: [Bool]) {
        self.port_name = port_name
        self.baud_rate = baud_rate
        self.save_path = save_path
        self.config_path = config_path
        self.actions = actions
        self.persons = persons
        self.ena_sensor = ena_sensor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.port_name = try container.decode(String.self, forKey: .port_name)
        self.baud_rate = try container.decode(Int.self, forKey: .baud_rate)
        self.save_path = try container.decode(String.self, forKey: .save_path)
        self.config_path = try container.decode(String.self, forKey: .config_path)
        self.actions = try container.decode([Action].self, forKey: .actions)
        self.persons = try container.decode([Person].self, forKey: .persons)
        self.ena_sensor = try container.decode([Bool].self, forKey: .ena_sensor)
    }
    
    init?(json: Data){
        if let newValue = try? JSONDecoder().decode(Config.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
}
