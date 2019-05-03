//
//  DashboardViewController.swift
//  chakuyo-bako
//
//  Created by Matsuno Shunya on 2019/04/24.
//  Copyright © 2019年 Matsuno Shunya. All rights reserved.
//

import UIKit
import CoreBluetooth
import RealmSwift
import Charts

enum Environment: Int {
    case temperature = 0
    case humidity = 1
    case pressure = 2
}

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BluetoothDelegate {    

    let bluetoothManager = CoreBluetoothManager.getInstance()

    @IBOutlet weak var tableView: UITableView!
    
    var isViewAppear = true
    var intervalTimer: Timer?
    var tempCal: Double = 0.0
    var humCal: Double = 0.0
    var presCal: Double = 0.0
    
    var intervalSecond: Double = 300
    
    let realm = try! Realm()
    let calendar = Calendar(identifier: .gregorian)
    var date: Date = Date()
    
    var beforeDate: Date = Date()
    var measuringDate: MeasuringDate = MeasuringDate()
    
    var connectingView: LoadingView!
    let notificationManager = NotificationManager()
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
    
    let formatter = DateFormatter()
    
    var isMock = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        NotificationCenter.default.addObserver(self, selector: #selector(viewWillEnterForeground), name: NSNotification.Name(rawValue: "applicationWillEnterForeground"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(viewDidEnterBackground), name: NSNotification.Name(rawValue: "applicationDidEnterBackground"), object: nil)
        
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        
        // ビューを初期化
        initView()
        
        // バックグラウンドで処理を登録
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
        }
        intervalTimer = Timer.scheduledTimer(timeInterval: intervalSecond, target: self, selector: #selector(update), userInfo: nil, repeats: false)
        
        update()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        connectingView.isHidden = false
        self.isViewAppear = true
        bluetoothManager.delegate = self
        
        // read settings
        var setting = realm.objects(Setting.self).first
        if setting == nil {
            let firstSetting = Setting()
            try! realm.write {
                firstSetting.intervalTime = 300
                realm.add(firstSetting)
            }
            setting = firstSetting
        }
        intervalSecond = setting!.intervalTime
        
        
        // Init Realm Database
        let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
        guard let newDate = realm.objects(MeasuringDate.self).filter("date >= %@ AND date < %@", startDate!, endDate!).first else {
            let newDate = MeasuringDate()
            newDate.date = Date()
            
            try! realm.write {
                realm.add(newDate)
            }
            
            self.measuringDate = newDate
            
            update()
            return
        }
        
        self.measuringDate = newDate
        update()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // isViewAppear = false
    }
    
    @objc func update() {
        connectingView.isHidden = false
        bluetoothManager.readEnvironmentData()
        
        if (isMock) {
            let date = Date()
            let env = EnvironmentData()
            
            tempCal = Double.random(in: 23.5 ... 26.0)
            humCal = Double.random(in: 46.0 ... 51.0)
            presCal = Double.random(in: 995 ... 1000)
            
            env.temperture = tempCal
            env.humidity = humCal
            env.pressure = presCal
            env.measuringDate = date
            
            try! realm.write {
                measuringDate.environmentData.append(env)
                measuringDate.date = date
                realm.add(measuringDate)
            }            
            
            if isViewAppear {
                connectingView.isHidden = true
                tableView.reloadData()
            }
        }
        
    }
    
    private func initView() {
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 29 / 255, green: 150 / 255, blue: 120 / 255, alpha: 1)
        self.navigationController?.navigationBar.tintColor = .white
        
        // TableViewの設定
        connectingView = Bundle.main.loadNibNamed("LoadingView", owner: self, options: nil)!.first! as? LoadingView
        connectingView.backgroundColor = UIColor.clear
        connectingView.messageLabel.text = "データ取得中"
        connectingView.frame = self.view.frame
        connectingView.isHidden = false
        self.view.addSubview(connectingView)
        
        // TableViewの設定
        tableView.register(UINib(nibName: "DashboardTableViewCell", bundle: nil), forCellReuseIdentifier: "DashboardTableViewCell")
        tableView.backgroundColor = UIColor(red: 241/255, green: 242/255, blue: 244/255, alpha: 1)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    /*
     * Chartを表示
     * chartViewにdataを詰める
     */
    private func drawChart(chartView: LineChartView, type: Environment) {
        var dates: [String] = []
        
        let values = self.measuringDate.environmentData.enumerated().map {(arg) -> ChartDataEntry in
            let (index, envData) = arg
            var yVal: Double = 0.0
            
            let date = formatter.string(from: envData.measuringDate!)
            dates.append(date)
            
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
        
        let set1 = LineChartDataSet(entries: values, label: nil)
        set1.axisDependency = .left
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
        
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:dates)
        chartView.xAxis.granularity = 10
        chartView.data = data
    }
    
    @IBAction func settingButtonPushed(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "SettingViewController") as? SettingViewController
        let navigationController = UINavigationController(rootViewController: next!)
        
        self.present(navigationController,animated: true, completion: nil)
    }
    
    /**
     * MARK - BluetoothDelegate
    **/
    func didReadEnvironmentData(tempCal: Double, presCal: Double, humCal: Double) {
        intervalTimer?.invalidate()
        intervalTimer = Timer.scheduledTimer(timeInterval: intervalSecond, target: self, selector: #selector(update), userInfo: nil, repeats: true)

        print("=============didReadEnvironmentData================")
        
        date = Date()
        // Temporary: 通信が遅くなってきたらち通知するように。
        if UIApplication.shared.applicationState == .background &&  beforeDate < Date(timeIntervalSinceNow: -180) {
            notificationManager.notificationDisconnect(title: "Chakuyo-bakoの通信が遅くなってきたかもしれません",
                                                       body: "アプリを起動して通信ができているか確認してください。")
        }
        beforeDate = date
        
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
        
        self.tempCal = tempCal
        self.humCal = humCal
        self.presCal = presCal
        
        if isViewAppear {
            connectingView.isHidden = true
            tableView.reloadData()
        }
    }
    
    func didLowBattery() {
        notificationManager.notificationDisconnect(title: "Chakuyo-bakoの電池が少なくなっています",
                                                   body: "Chakuyo-bakoの電池を交換してあげてください。")
    }

    
    func didDisconnectPeripheral(_ peripheral: CBPeripheral) {
        intervalTimer?.invalidate()
    
        notificationManager.notificationDisconnect(title: "Chakuyo-bakoとの接続が切れました",
            body: "大変です！Chakuyo-bakoを見失いました！近くにChakuyo-bakoがいるか確認してください。")
        
        bluetoothManager.delegate = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     * MARK - TableViewDelegate
     **/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let next = storyboard!.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
        next?.type = Environment(rawValue: indexPath.row)
        switch indexPath.row {
            case Environment.temperature.rawValue:
                next?.currentVal = ceil(tempCal * 10) / 10
                break
            case Environment.humidity.rawValue:
                next?.currentVal = ceil(humCal)
                break
            case Environment.pressure.rawValue:
                next?.currentVal = ceil(presCal * 10) / 10
                break
            default: break
        }
        self.navigationController?.pushViewController(next!, animated: true)
    }
    
    // MARK: Table View Datasource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DashboardTableViewCell = tableView.dequeueReusableCell(withIdentifier: "DashboardTableViewCell", for: indexPath) as! DashboardTableViewCell

        switch indexPath.row {
        case Environment.temperature.rawValue:
            cell.environmentLabel.text = "気温"
            cell.valueLabel.text = String(ceil(tempCal*100)/100) + "℃"
            self.drawChart(chartView: cell.chartView, type: .temperature)
        case Environment.humidity.rawValue:
            cell.environmentLabel.text = "湿度"
            cell.valueLabel.text = String(ceil(humCal*100)/100) + "%"
            self.drawChart(chartView: cell.chartView, type: .humidity)
        case Environment.pressure.rawValue:
            cell.environmentLabel.text = "気圧"
            cell.valueLabel.text = String(ceil(presCal*100)/100) + "hPa"
            self.drawChart(chartView: cell.chartView, type: .pressure)
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clear
    }
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clear
    }
    
    // AppDelegate -> applicationWillEnterForegroundの通知
    @objc func viewWillEnterForeground(notification: NSNotification?) {
        intervalSecond = 300
        intervalTimer?.invalidate()
        intervalTimer = Timer.scheduledTimer(timeInterval: intervalSecond, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    // AppDelegate -> applicationDidEnterBackgroundの通知
    @objc func viewDidEnterBackground(notification: NSNotification?) {
        intervalSecond = 300
        intervalTimer?.invalidate()
        intervalTimer = Timer.scheduledTimer(timeInterval: intervalSecond, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
}
