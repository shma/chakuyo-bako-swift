//
//  DebugViewController.swift
//  chakuyo-bako
//
//  Created by Matsuno Shunya on 2019/05/01.
//  Copyright © 2019年 Matsuno Shunya. All rights reserved.
//

import UIKit
import RealmSwift

class ExportViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let realm = try! Realm()
    let calendar = Calendar(identifier: .gregorian)
    var date: Date = Date()
    let formatter = DateFormatter()
    
    var measuringDate: MeasuringDate = MeasuringDate()
    
    @IBOutlet weak var tableView: UITableView!
    var connectingView: LoadingView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return measuringDate.environmentData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let count = measuringDate.environmentData.count
        let envdata = measuringDate.environmentData[(count - 1) - indexPath.row]
        let date = formatter.string(from: envdata.measuringDate!)
        
        let newCell = tableView.dequeueReusableCell(withIdentifier: "debugCell", for: indexPath)
        newCell.textLabel?.text = "\(date), \(envdata.temperture), \(ceil(envdata.humidity * 100) / 100) , \(envdata.pressure)"
        newCell.selectionStyle = .none
        return newCell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")
        
        // Do any additional setup after loading the view.
        connectingView = Bundle.main.loadNibNamed("LoadingView", owner: self, options: nil)!.first! as? LoadingView
        connectingView.backgroundColor = UIColor.clear
        connectingView.messageLabel.text = "ファイルを作成中"
        connectingView.frame = self.view.frame
        connectingView.isHidden = true
        self.view.addSubview(connectingView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
        
        guard let newDate = realm.objects(MeasuringDate.self).filter("date >= %@ AND date < %@", startDate!, endDate!).first else {
            let newDate = MeasuringDate()
            newDate.date = date
            
            try! realm.write {
                realm.add(newDate)
            }
            
            self.measuringDate = newDate
            return
        }
        self.measuringDate = newDate
    }
    
    @IBAction func exportButtonDidPush(_ sender: Any) {
        connectingView.isHidden = false
    
        
        let filePath = prepareFile()
        var text = "時間, 気温, 湿度, 気圧\r\n"
        self.tmpWriter(message: text, dataPath: filePath)
        measuringDate.environmentData.forEach { (env) in
            text = "\(formatter.string(from: env.measuringDate!)), \(env.temperture), \(ceil(env.humidity * 100) / 100) , \(env.pressure)\r\n"
            self.tmpWriter(message: text, dataPath: filePath)
        }
        
        connectingView.isHidden = true
        
        let url = NSURL(fileURLWithPath: filePath)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
        self.present(vc, animated: true, completion: nil)
        
    }
    
    func prepareFile() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let dataPath = documentsPath + "/" + "chakuyobako.csv"
        
        if( FileManager.default.fileExists( atPath: dataPath) ) {
            let manager = FileManager()
            do {
                try manager.removeItem(atPath: dataPath)
            } catch {
                print("ERROR")
            }
            
        } else {
            
        }
        
        return dataPath
    }
    
    func tmpWriter(message: String, dataPath: String) {
        let file = OutputStream(toFileAtPath: dataPath, append: true)
        file?.open()
        let tmps = [UInt8](message.utf8)
        let bytes = UnsafePointer<UInt8>(tmps)
        let size = message.lengthOfBytes(using: String.Encoding.utf8)
        file?.write(bytes, maxLength: size)
        file?.close()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
