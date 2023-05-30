//
//  ViewController.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 30.05.2023.
//

import UIKit

class ViewController: UIViewController {
    
    private let weatherConditions: [String: String] = [
        "overcast": "Облачно",
        "clear": "Ясно",
        "partly-cloudy": "Переменная облачность",
        "drizzle": "Морось",
        "light-rain": "Небольшой дождь",
        "rain": "Дождь",
        "moderate-rain": "Умеренно сильный дождь",
        "heavy-rain": "сильный дождь",
        "continuous-heavy-rain": "длительный сильный дождь",
        "showers": "ливень",
        "wet-snow": "дождь со снегом",
        "light-snow": "небольшой снег",
        "snow": "снег",
        "snow-showers": "снегопад",
        "hail": "град",
        "thunderstorm": "гроза",
        "thunderstorm-with-rain": "дождь с грозой",
        "thunderstorm-with-hail": "гроза с градом"
    ]
    
    private let tempJoke: [Int: String] = [
        13: "Прохладно"
    ]
    
    
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchDataFromAPI()
    }
    
    func fetchDataFromAPI() {
        guard let url = URL(string: "https://api.weather.yandex.ru/v2/informers?lat=50.6107&lon=36.5802") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("937ce0f2-8247-49e0-9d9a-c4bdaeab8f93", forHTTPHeaderField: "X-Yandex-API-Key")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Ошибка при выполнении запроса: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Данные пустые")
                return
            }
            
            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                
                DispatchQueue.main.async {
                    self.updateUI(with: weatherData)
                }
            } catch {
                print("Ошибка при декодировании данных: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func updateUI(with weatherData: WeatherData) {
        
        switch weatherData.fact.temp {
        case 0...10:
            temperatureLabel.text = "Холодно"
        case 11...14:
            temperatureLabel.text = "Прохладно"
        case 15...20:
            temperatureLabel.text = "Тепло"
        case 21...27:
            temperatureLabel.text = "Жарко"
        case 28...35:
            temperatureLabel.text = "Вообще жарища"
        default:
            temperatureLabel.text = "Мороз"
        }
        
       tempLabel.text = "\(weatherData.fact.temp)°C"
        
        
        if let condition = weatherConditions[weatherData.fact.condition] {
            conditionLabel.text = condition
        } else {
            conditionLabel.text = weatherData.fact.condition
        }
    }
}
