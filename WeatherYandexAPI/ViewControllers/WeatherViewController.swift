//
//  ViewController.swift
//  WeatherYandexAPI
//
//  Created by Alexey Manokhin on 30.05.2023.
//

import UIKit
import CoreLocation
import SVGKit

class WeatherViewController: UIViewController, CLLocationManagerDelegate {

    private let networkManager = NetworkManager.shared
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var locationManager: CLLocationManager!

    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var recommendationsLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var feelsLikeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var weatherIconImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        recommendationsLabel.textColor = .systemBlue
        initLocationManager()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopUpdatingLocation()
    }

    private func setupUI() {
        activityIndicator.startAnimating()
        recommendationsLabel.textColor = .systemBlue
    }

    private func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        checkLocationAuthorization()
    }

    private func checkLocationAuthorization() {
        
        let manager = CLLocationManager()
        
        switch manager.authorizationStatus {
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
        let manager = CLLocationManager()
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    private func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
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

        // Проверка, был ли запрос на получение данных о погоде уже отправлен
        guard !networkManager.isFetchingData else {
            return
        }

        fetchDataFromAPI()
    }


    private func fetchDataFromAPI() {
        NetworkManager.shared.fetchData(for: latitude, longitude: longitude) { [weak self] weatherData, error in
            guard let self = self else {
                return
            }

            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    // Запрос был отменен, не требуется дальнейшая обработка
                    return
                }

                print("Ошибка при получении данных о погоде: \(error)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                return
            }

            // Обработка полученных данных о погоде
            guard let weatherData = weatherData else {
                print("Получены пустые данные о погоде")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                return
            }

            DispatchQueue.main.async {
                self.updateUI(with: weatherData)
                self.activityIndicator.stopAnimating()
            }
        }
    }


    private func updateUI(with weatherData: WeatherData) {
        if let icon = weatherData.fact.icon, let iconURL = URL(string: "https://yastatic.net/weather/i/icons/funky/dark/\(icon).svg") {
            URLSession.shared.dataTask(with: iconURL) { [weak self] (data, _, error) in
                if let data = data, let svgImage = SVGKImage(data: data) {
                    DispatchQueue.main.async {
                        self?.weatherIconImageView.image = svgImage.uiImage
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showErrorAlert(message: "Ошибка при загрузке иконки погоды")
                    }
                }
            }.resume()
        }

        recommendationsLabel.text = getRecommendations(for: Double(weatherData.fact.feelsLike))
        tempLabel.text = "Температура: \(weatherData.fact.temp)°C"
        feelsLikeLabel.text = "Ощущается как: \(weatherData.fact.feelsLike)°C"
        conditionLabel.text = networkManager.getConditionLabel(for: weatherData.fact.condition)
    }

    private func getRecommendations(for feelsLike: Double) -> String {
        switch feelsLike {
        case 1...10:
            return "Холодно. Наденьте легкую теплую куртку или пуловер, утепленные брюки или джинсы"
        case 11...17:
            return "Прохладно. Наденьте легкую куртку или ветровку, брюки или джинсы"
        case 18...27:
            return "Тепло. Выбирайте легкую одежду: Футболку, легкие брюки или шорты. Используйте легкую обувь, такую как сандалии или кроссовки."
        case 28...35:
            return "Жарко. Носите легкую и воздухопроницаемую одежду. Используйте шорты, футболки, топы или платья из легких материалов. Оптимально выбирать светлые цвета, которые отражают солнечные лучи. Наденьте шляпу или кепку, чтобы защититься от солнца. Используйте удобную и дышащую обувь, например, сандалии или открытые туфли."
        case 36...:
            return "Очень жарко. По возможности, оставайтесь в прохладном помещении. При выходе на улицу одевайтесь очень легко, пейте больше воды и старайтесь проводить меньше времени под прямыми солнечными лучами."
        default:
            return "Мороз. Наденьте теплую куртку (пуховик, пальто), шапку, теплую обувь, теплые штаны."
        }
    }

    private func showLocationPermissionAlert() {
        let alert = UIAlertController(title: "Ошибка", message: "Вы не разрешили определение местоположения. Погода будет отображаться некорректно. Пожалуйста, разрешите доступ в настройках приложения.", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Настройки", style: .default) { _ in
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

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}
