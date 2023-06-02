//
//  NetworkManager.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 02.06.2023.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private let weatherConditions: [String: String] = [
        "overcast": "облачно",
        "clear": "ясная погода",
        "partly-cloudy": "переменная облачность",
        "drizzle": "морось",
        "light-rain": "идет небольшой дождь",
        "rain": "идет дождь",
        "moderate-rain": "идет умеренно сильный дождь",
        "heavy-rain": "идет сильный дождь",
        "continuous-heavy-rain": "идет длительный сильный дождь",
        "showers": "ливень",
        "wet-snow": "идет дождь со снегом",
        "light-snow": "идет небольшой снег",
        "snow": "идет снег",
        "snow-showers": "снегопад",
        "hail": "идет град",
        "thunderstorm": "гроза",
        "thunderstorm-with-rain": "идет дождь с грозой",
        "thunderstorm-with-hail": "гроза с градом",
        "cloudy": "облачно с прояснениями",
    ]
    
    private init() {}
    
    func fetchData(for latitude: Double, longitude: Double, completion: @escaping (WeatherData?) -> Void) {
        guard let url = URL(string: "https://api.weather.yandex.ru/v2/informers?lat=\(latitude)&lon=\(longitude)") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("937ce0f2-8247-49e0-9d9a-c4bdaeab8f93", forHTTPHeaderField: "X-Yandex-API-Key")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Ошибка при выполнении запроса: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Данные пустые")
                completion(nil)
                return
            }
            
            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                completion(weatherData)
            } catch {
                print("Ошибка при декодировании данных: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    func getConditionLabel(for condition: String) -> String {
        if let translatedCondition = weatherConditions[condition] {
            return "На улице " + translatedCondition
        } else {
            return condition
        }
    }
}
