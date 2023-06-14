//
//  WeatherData.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 30.05.2023.
//

struct WeatherData: Codable {
    let fact: Fact
}

struct Fact: Codable {
    let temp: Int
    let feelsLike: Int
    let condition: String
    let icon: String?
    
    private enum CodingKeys: String, CodingKey {
        case temp
        case condition
        case feelsLike = "feels_like"
        case icon
    }
}
