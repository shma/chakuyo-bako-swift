//
//  DetailViewController.swift
//  chakuyo-bako
//
//  Created by Matsuno Shunya on 2019/04/28.
//  Copyright © 2019年 Matsuno Shunya. All rights reserved.
//

import UIKit
import RealmSwift
import Charts
import Firebase
import FirebaseFirestore

class DetailViewController: UIViewController, BluetoothDelegate {
    
    let bluetoothManager = CoreBluetoothManager.getInstance()
    let realm = try! Realm()
    var measuringDate: MeasuringDate = MeasuringDate()
    var type: Environment!
    
    var currentVal: Double = 0.0
    var typeValJa: String = ""
    var typeValEn: String = ""
    
    var maxValue: Double = 0.0
    var minValue: Double = 0.0
    var averageValue: Double = 0.0
    var differenceValue: Double = 0.0
    var detailValue: Double = 0.0
    
    var unit: String =  ""
    
    @IBOutlet weak var adviseTextLabel: UILabel!
    
    @IBOutlet weak var summaryView: UIView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var adviseView: UIView!
    
    @IBOutlet weak var headerTypeLabel: UILabel!
    @IBOutlet weak var headerValueLabel: UILabel!
    @IBOutlet weak var chartView: LineChartView!
    
    @IBOutlet weak var detailMaxLabel: UILabel!
    @IBOutlet weak var detailMinLabel: UILabel!
    @IBOutlet weak var detailDifferenceLabel: UILabel!
    @IBOutlet weak var detailAverageLabel: UILabel!
    
    @IBOutlet weak var detailMaxValueLabel: UILabel!
    @IBOutlet weak var detailMinValueLabel: UILabel!
    @IBOutlet weak var detailDifferenceValueLabel: UILabel!
    @IBOutlet weak var detailAverageValueLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        bluetoothManager.delegate = self
        
        // Init Realm Database
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())

        // 今日のデータがあるかチェック。なければ作る
        guard let newDate = realm.objects(MeasuringDate.self).filter("date >= %@ AND date < %@", startDate!, endDate!).first else {
            return
        }
        
        measuringDate = newDate
        
        self.view.backgroundColor = UIColor(red: 241/255, green: 242/255, blue: 244/255, alpha: 1)
        parentView.backgroundColor = UIColor(red: 241/255, green: 242/255, blue: 244/255, alpha: 1)
        
        summaryView.backgroundColor = .white
        summaryView.layer.cornerRadius = 8
        summaryView.layer.shadowOpacity = 0.25
        summaryView.layer.shadowRadius = 5
        summaryView.layer.shadowOffset = CGSize(width: 0, height: 10)
        
        adviseView.backgroundColor = .white
        adviseView.layer.cornerRadius = 8
        adviseView.layer.shadowOpacity = 0.25
        adviseView.layer.shadowRadius = 5
        adviseView.layer.shadowOffset = CGSize(width: 0, height: 10)
        
        switch type {
        case .temperature?:
            unit = "℃"
            typeValJa = "気温"
            typeValEn = "temperature"
            detailMaxLabel.text = "最高気温"
            detailMinLabel.text = "最低気温"
            detailDifferenceLabel.text = "気温差"
            detailAverageLabel.text = "平均気温"
            
            break
        case .humidity?:
            unit = "%"
            typeValJa = "湿度"
            typeValEn = "humidity"
            detailMaxLabel.text = "最高湿度"
            detailMinLabel.text = "最低湿度"
            detailDifferenceLabel.text = "湿度差"
            detailAverageLabel.text = "平均湿度"

            break
        case .pressure?:
            unit = "hPa"
            typeValJa = "気圧"
            typeValEn = "pressure"
            detailMaxLabel.text = "最高気圧"
            detailMinLabel.text = "最低気圧"
            detailDifferenceLabel.text = "気圧差"
            detailAverageLabel.text = "平均気圧"

            break
        case .none: break
        }
        
        headerTypeLabel.text = typeValJa
        
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = false
        chartView.xAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.highlightPerTapEnabled = false
        chartView.doubleTapToZoomEnabled = false
        // 重い
        // drawChart(chartView: chartView, type: type)
        
        chartView.noDataText = "データを取得しています"
        // バッティングしない？？
        bluetoothManager.readEnvironmentData()
        
        getAdvise()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        bluetoothManager.delegate = nil
    }
    
    // delegate
    func didReadEnvironmentData(tempCal: Double, presCal: Double, humCal: Double) {
        switch type {
        case .temperature?:
            detailValue = ceil(tempCal * 100) / 100
            break
        case .humidity?:
            detailValue = ceil(humCal * 100) / 100
            break
        case .pressure?:
            detailValue = ceil(presCal * 100) / 100
            break
        case .none: break
        }
        
        headerValueLabel.text = String(detailValue) + unit
        drawChart(chartView: chartView, type: type)
        calcEnvironments()
        
        let calendar = Calendar(identifier: .gregorian)
        let date = Date()
        let environmentData = EnvironmentData()
        environmentData.humidity = humCal
        environmentData.pressure = presCal
        environmentData.temperture = tempCal
        environmentData.measuringDate = date
        let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
        guard let _ = realm.objects(MeasuringDate.self).filter("date >= %@ AND date < %@", startDate!, endDate!).first else {
            let newDate = MeasuringDate()
            newDate.date = date
            
            try! realm.write {
                newDate.environmentData.append(environmentData)
                realm.add(newDate)
            }
            self.measuringDate = newDate
            return
        }
        
        try! realm.write {
            measuringDate.environmentData.append(environmentData)
            realm.add(measuringDate)
        }
    }
    
    private func getAdvise() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let db = Firestore.firestore()

        db.collection(typeValEn).whereField("value", isEqualTo: currentVal).getDocuments() { (querySnapshot, err) in
            if let _ = err {
                self.adviseTextLabel.text = "気温・湿度・気圧で知ってる値があったら教えるよ！"
            } else {
                let documents = querySnapshot!.documents
                
                if documents.count == 0 {
                    self.adviseTextLabel.text = "気温・湿度・気圧で知ってる値があったら教えるよ！"
                    return
                }
                
                let randVal = Int.random(in: 0 ... (documents.count - 1))
                
                let data = documents[randVal].data()
                let timestamp = data["date"] as? Timestamp
                let dateString = formatter.string(from: (timestamp?.dateValue())!)
                
                guard let nameString = data["name"] else {
                    return
                }
                
                self.adviseTextLabel.text = "\(dateString)の\(nameString)と同じくらいの\(self.typeValJa)だよ。"
            }
        }
    }

    
    private func calcEnvironments() {
        let environmentData = measuringDate.environmentData
        let environmentCount = Double(environmentData.count)
        
        switch type {
        case .temperature?:
            maxValue = environmentData.reduce(environmentData[0].temperture) { (res1, res2) in
                max(res1, res2.temperture)
            }
            minValue = environmentData.reduce(environmentData[0].temperture) { (res1, res2) in
                min(res1, res2.temperture)
            }
            averageValue = environmentData.reduce(environmentData[0].temperture, { (res1, res2) -> Double in
                return res1 + res2.temperture
            }) / environmentCount
            
            break
        case .humidity?:
            maxValue = environmentData.reduce(environmentData[0].humidity) { (res1, res2) in
                max(res1, res2.humidity)
            }
            minValue = environmentData.reduce(environmentData[0].humidity) { (res1, res2) in
                min(res1, res2.humidity)
            }
            averageValue = environmentData.reduce(environmentData[0].humidity, { (res1, res2) -> Double in
                return res1 + res2.humidity
            }) / environmentCount
            break
        case .pressure?:
            maxValue = environmentData.reduce(environmentData[0].pressure) { (res1, res2) in
                max(res1, res2.pressure)
            }
            minValue = environmentData.reduce(environmentData[0].pressure) { (res1, res2) in
                min(res1, res2.pressure)
            }
            averageValue = environmentData.reduce(environmentData[0].pressure, { (res1, res2) -> Double in
                return res1 + res2.pressure
            }) / environmentCount
            break
        case .none: break
        }
        
        differenceValue = maxValue - minValue
        
        detailMaxValueLabel.text = String(ceil(maxValue * 100) / 100) + unit
        detailMinValueLabel.text = String(ceil(minValue * 100) / 100) + unit
        detailDifferenceValueLabel.text = String(ceil(differenceValue * 100) / 100) + unit
        detailAverageValueLabel.text = String(ceil(averageValue * 100) / 100) + unit
    }
    
    private func drawChart(chartView: LineChartView, type: Environment) {
        let values = self.measuringDate.environmentData.enumerated().map {(arg) -> ChartDataEntry in
            let (index, envData) = arg
            var yVal: Double = 0.0
            switch type {
            case .humidity :
                yVal = envData.humidity
                break
            case .temperature:
                yVal = envData.temperture
                break
            case .pressure:
                yVal = envData.pressure
                break
            }
            return ChartDataEntry(x: Double(index), y: yVal)
        }
        
        let set1 = LineChartDataSet(entries: values, label: "気温")
        set1.axisDependency = .left
        
        var color: UIColor!
        switch type {
        case .humidity :
            color = UIColor(red: 0/255, green: 144/255, blue: 232/255, alpha: 1)
            break
        case .temperature:
            color = UIColor(red: 255/255, green: 90/255, blue: 95/255, alpha: 1)
            break
        case .pressure:
            color = UIColor(red: 237/255, green: 174/255, blue: 73/255, alpha: 1)
            break
        }
        
        set1.setColor(color)
        set1.fillColor = color
        set1.lineWidth = 1.5
        set1.drawCirclesEnabled = false
        set1.drawValuesEnabled = false
        set1.drawFilledEnabled = true
        set1.fillAlpha = 1.0
        set1.mode = .cubicBezier
        
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        
        let data = LineChartData(dataSet: set1)
        data.setValueTextColor(.white)
        data.setValueFont(.systemFont(ofSize: 9, weight: .light))
        
        
        chartView.data = data
    }

}
