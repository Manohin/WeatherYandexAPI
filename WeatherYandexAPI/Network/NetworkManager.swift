//
//  NetworkManager.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 03.06.2023.
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
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    
    private init() {}
    
    func fetchData(for latitude: Double, longitude: Double, completion: @escaping (WeatherData?, Error?) -> Void) {
        guard let url = URL(string: "https://api.weather.yandex.ru/v2/informers?lat=\(latitude)&lon=\(longitude)") else {
            completion(nil, NetworkError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(APIKeys.yandexAPIKey, forHTTPHeaderField: "X-Yandex-API-Key")
        
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NetworkError.emptyData)
                return
            }
            
            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                completion(weatherData, nil)
            } catch {
                completion(nil, NetworkError.decodingError(error))
            }
        }
        
        task.resume()
    }
    
    func getConditionLabel(for condition: String) -> String {
        if let translatedCondition = weatherConditions[condition] {
            return "На улице " + translatedCondition
        } else {
            return condition
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case emptyData
    case decodingError(Error)
}
