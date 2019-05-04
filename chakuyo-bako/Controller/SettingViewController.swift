//
//  SettingViewController.swift
//  chakuyo-bako
//
//  Created by Matsuno Shunya on 2019/04/28.
//  Copyright © 2019年 Matsuno Shunya. All rights reserved.
//

import UIKit
import RealmSwift

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    let realm = try! Realm()
    let bluetoothManager = CoreBluetoothManager.getInstance()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 29 / 255, green: 150 / 255, blue: 120 / 255, alpha: 1)
        self.navigationController?.navigationBar.tintColor = .white
        
        tableView.backgroundColor = UIColor(red: 241/255, green: 242/255, blue: 244/255, alpha: 1)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    @IBAction func closeButtonPushed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            deleteAlert()
            break
        case 1:
            disconnectAlert()
            break
        case 2:
            let next = storyboard!.instantiateViewController(withIdentifier: "ExportViewController") as? ExportViewController
            self.navigationController?.pushViewController(next!, animated: true)
            break
        case 3:
            // styleをActionSheetに設定
            let alertSheet = UIAlertController(title: "データの間隔を設定", message: "間隔を選択してください", preferredStyle: UIAlertController.Style.actionSheet)
            
            // 自分の選択肢を生成
            let action1 = UIAlertAction(title: "5秒に1回", style: UIAlertAction.Style.default, handler: {
                (action: UIAlertAction!) in
                guard let setting = self.realm.objects(Setting.self).first else {
                    return
                }
                
                try! self.realm.write {
                    setting.intervalTime = 5
                    self.realm.add(setting)
                }
                self.tableView.reloadData()
            })
            let action2 = UIAlertAction(title: "30秒に1回", style: UIAlertAction.Style.default, handler: {
                (action: UIAlertAction!) in
                guard let setting = self.realm.objects(Setting.self).first else {
                    return
                }
                
                try! self.realm.write {
                    setting.intervalTime = 30
                    self.realm.add(setting)
                }
                self.tableView.reloadData()
            })
            let action3 = UIAlertAction(title: "1分に1回（推奨）", style: UIAlertAction.Style.default, handler: {
                (action: UIAlertAction!) in
                guard let setting = self.realm.objects(Setting.self).first else {
                    return
                }
                
                try! self.realm.write {
                    setting.intervalTime = 60
                    self.realm.add(setting)
                }
                self.tableView.reloadData()
            })
            
            let action4 = UIAlertAction(title: "5分に1回", style: UIAlertAction.Style.default, handler: {
                (action: UIAlertAction!) in
                guard let setting = self.realm.objects(Setting.self).first else {
                    return
                }
                
                try! self.realm.write {
                    setting.intervalTime = 300
                    self.realm.add(setting)
                }
                self.tableView.reloadData()
            })
            
            let action5 = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
                (action: UIAlertAction!) in
            })
            
            // アクションを追加.
            alertSheet.addAction(action1)
            alertSheet.addAction(action2)
            alertSheet.addAction(action3)
            alertSheet.addAction(action4)
            alertSheet.addAction(action5)
            
            self.present(alertSheet, animated: true, completion: nil)
            break
        default :
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    @objc func switchTriggered() {
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let newCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
//        if newCell.accessoryView == nil{
//            let switchView = UISwitch(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
//            switchView.isOn = false
//            switchView.tag = indexPath.row
//            switchView.addTarget(self, action: #selector(switchTriggered), for: .valueChanged)
//            newCell.accessoryView = switchView
//        }
        
        switch indexPath.row {
        case 0:
            newCell.textLabel?.text = "本日のデータを削除する"
            break
        case 1:
            newCell.textLabel?.text = "Chakuyo-bakoを切断する"
            break
        case 2:
            newCell.textLabel?.text = "データをエクスポートする"
            break;
        case 3:
            
            
            guard let setting = self.realm.objects(Setting.self).first else {
                break
            }
            var viewableSecond = ""
            if (setting.intervalTime > 60) {
                viewableSecond = "(\(Int(setting.intervalTime / 60))分に1回)"
            } else {
                viewableSecond = "(\(Int(setting.intervalTime))秒に1回)"
            }
            
            newCell.textLabel?.text = "データ取得の間隔を設定する" + viewableSecond
            
            break;
        default :
            break
        }

        return newCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
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
    
    
    private func deleteAlert() {
        let alert: UIAlertController = UIAlertController(title: "本日のデータを削除", message: "削除してもいいですか？", preferredStyle:  UIAlertController.Style.alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{

            (action: UIAlertAction!) -> Void in
            print("OK")
            let calendar = Calendar(identifier: .gregorian)
            let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())
            let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
            
            guard let newDate = self.realm.objects(MeasuringDate.self).filter("date >= %@ AND date < %@", startDate!, endDate!).first else {
                return
            }

            try! self.realm.write {
                self.realm.delete(newDate)
            }
            
            self.deleteCompleteAlert()
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("Cancel")
        })
        
        // ③ UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
    private func disconnectAlert() {
        let alert: UIAlertController = UIAlertController(title: "切断", message: "Chakuyob-bakoとの通信を切断してもいいですか？", preferredStyle:  UIAlertController.Style.alert)
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            // 一気にdismissしたいなぁ
            self.bluetoothManager.disconnectPeripheral()
            self.dismiss(animated: true, completion: nil)
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("Cancel")
        })
        
        // ③ UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteCompleteAlert() {
        let alert: UIAlertController = UIAlertController(title: "削除完了", message: "本日のデータが削除されました", preferredStyle:  UIAlertController.Style.alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)

        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)
    }

    
}
