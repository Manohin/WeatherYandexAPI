//
//  WeatherData.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 30.05.2023.
//

import UIKit

struct WeatherData: Codable {
    let fact: Fact
    
    private enum CodingKeys: String, CodingKey {
        case fact = "fact"
    }
}

struct Fact: Codable {
    let temp: Int
    let feelsLike: Int
    let condition: String
    let icon: String?
    
    private enum CodingKeys: String, CodingKey {
        case temp = "temp"
        case condition = "condition"
        case feelsLike = "feels_like"
        case icon = "icon"
    }
}
