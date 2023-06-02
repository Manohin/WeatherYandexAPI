//
//  ViewController.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 30.05.2023.
//

import UIKit
import CoreLocation
import SVGKit

final class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
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
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var locationManager: CLLocationManager!
    
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var recommendationsLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet var feelsLikeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var weatherIconImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchDataFromAPI()
        recommendationsLabel.textColor = .systemBlue
        
        // Инициализация CLLocationManager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Запуск мониторинга местоположения
        startUpdatingLocation()
    }
    
    private func setupUI() {
        activityIndicator.startAnimating()
        recommendationsLabel.textColor = .systemBlue
    }
    
    private func checkLocationAuthorization() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            showLocationPermissionAlert()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func startUpdatingLocation() {
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        
        fetchDataFromAPI()
    }
    
    private func fetchDataFromAPI() {
        guard let url = URL(string: "https://api.weather.yandex.ru/v2/informers?lat=\(latitude)&lon=\(longitude)") else {
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
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                print("Ошибка при декодировании данных: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func updateUI(with weatherData: WeatherData) {
        if let icon = weatherData.fact.icon {
            let iconURLString = "https://yastatic.net/weather/i/icons/funky/dark/\(icon).svg"
            if let iconURL = URL(string: iconURLString) {
                DispatchQueue.global().async {
                    let svgImage = SVGKImage(contentsOf: iconURL)
                    DispatchQueue.main.async {
                        self.weatherIconImageView.image = svgImage?.uiImage
                    }
                }
            }
        }
        
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
            conditionLabel.text = "На улице" + " " + condition
        } else {
            conditionLabel.text = weatherData.fact.condition
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(title: "Ошибка", message: "Вы не разрешили определение местоположения. Погода будет отображаться некорректно. Пожалуйста, разрешите доступ в настройках приложения.", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Настройки", style: .default) { (_) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}
