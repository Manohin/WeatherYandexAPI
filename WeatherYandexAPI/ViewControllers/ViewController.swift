//
//  ViewController.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 30.05.2023.
//

import UIKit

final class ViewController: UIViewController {
    
    private let weatherConditions: [String: String] = [
        "overcast": "Облачно",
        "clear": "Ясно",
        "partly-cloudy": "Переменная облачность",
        "drizzle": "Морось",
        "light-rain": "Небольшой дождь",
        "rain": "Дождь",
        "moderate-rain": "Умеренно сильный дождь",
        "heavy-rain": "Сильный дождь",
        "continuous-heavy-rain": "Длительный сильный дождь",
        "showers": "Ливень",
        "wet-snow": "Дождь со снегом",
        "light-snow": "Небольшой снег",
        "snow": "Снег",
        "snow-showers": "Снегопад",
        "hail": "Град",
        "thunderstorm": "Гроза",
        "thunderstorm-with-rain": "Дождь с грозой",
        "thunderstorm-with-hail": "Гроза с градом",
        "cloudy": "Облачно с прояснениями",
    ]
    
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var recommendationsLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet var feelsLikeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchDataFromAPI()
        recommendationsLabel.textColor = .systemBlue
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
        
        switch weatherData.fact.feelsLike {
        case 1...10:
            recommendationsLabel.text = "Холодно. Наденьте легкую теплую куртку или пуловер, утепленные брюки или джинсы"
        case 11...17:
            recommendationsLabel.text = "Прохладно. Наденьте легкую куртку или ветровку, брюки или джинсы"
        case 18...27:
            recommendationsLabel.text = "Тепло. Выбирайте легкую одежду: Футболку, легкие брюки или шорты. Используйте легкую обувь, такую как сандалии или кроссовки."
        case 28...35:
            recommendationsLabel.text = "Жарко. Носите легкую и воздухопроницаемую одежду. Используйте шорты, футболки, топы или платья из легких материалов. Оптимально выбирать светлые цвета, которые отражают солнечные лучи. Наденьте шляпу или кепку, чтобы защититься от солнца. Используйте удобную и дышащую обувь, например, сандалии или открытые туфли."
        case 36...:
            recommendationsLabel.text = "Очень жарко. По возможности, оставайтесь в прохладном помещении. При выходе на улицу одевайтесь очень легко, пейте больше воды и старайтесь проводить меньше времени под прямыми солнечными лучами"
        default:
            recommendationsLabel.text = "Мороз. Наденьте теплую куртку (пуховик, пальто), шапку, теплую обувь, теплые штаны."
        }
        
        tempLabel.text = "Температура: \(weatherData.fact.temp)°C"
        feelsLikeLabel.text = "Ощущается как: \(weatherData.fact.feelsLike)°C"
        
        if let condition = weatherConditions[weatherData.fact.condition] {
            conditionLabel.text = "Погода:" + " " + condition
        } else {
            conditionLabel.text = weatherData.fact.condition
        }
    }
}
