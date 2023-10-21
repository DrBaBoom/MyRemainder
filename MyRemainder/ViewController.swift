//
//  ViewController.swift
//  MyRemainder
//
//  Created by Yura on 21.09.2023.
//

import UIKit
import UserNotifications
import RealmSwift

protocol NoteCreator {
    func createNote(txt: String, n1: Int?, n2: Int?)
}

protocol IsOnDelegate {
    func switchedNote(note: Note, flag: Bool)
}

class ViewController: UIViewController {
    
    @IBOutlet weak var btnPercents: UIButton!
    @IBOutlet weak var btnFreqency: UIButton!
    @IBOutlet weak var btnTime: UIButton!
    @IBOutlet var tblView: UITableView!
    @IBOutlet weak var switcher: UISwitch!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var bottomView: UIView!
    
    var supportPickerView = UIView()
    var picker: UIPickerView!
    
    var notesDataSource: [Note] = []
    var realm: Realm!
    
    var frequency = Duration.hours(1)
    var percent = 30
    var timeFrom = 9
    var timeTo = 21
    
    var downState: DownStates = .none
    
    var percents: [Int] = []
    var frequencys: [Duration] = [Duration.minutes(15), Duration.minutes(30), Duration.minutes(45), Duration.hours(1), Duration.hours(2), Duration.hours(3), Duration.hours(6), Duration.hours(12)]
    
    let userDefaults = UserDefaults.standard
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bottomView.layer.zPosition = 20
        createSupportPickerView()
        fillPersents(step: 5)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tblView.rowHeight = UITableView.automaticDimension
        realm = try! Realm()
        
        tblView.delegate = self
        tblView.dataSource = self
        
        for n in realm.objects(Note.self) {
            notesDataSource.append(n)
        }
        
        checkAllSwitchersOff()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willResignActive),
                                               name: UIScene.willDeactivateNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didActivate),
                                               name: UIScene.didActivateNotification,
                                               object: nil)
        readUserDefaults()
        setBtnTitles()
    }
    
    @objc func willResignActive(_ notification: Notification) {
        print("MTB")
    }
    
    @objc func didActivate(_ notification: Notification) {
        print("MTB")
        lblTime.text = UserDefaults.standard.string(forKey: "YuraKey") ?? "Never"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { f, e in
            if !f {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                  exit(0)
                }
            }
        })
    }

    @IBAction func btnAddPushed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "task_VC") as? Task_VC {
            vc.delegate = self
            self.present(vc, animated: true)
        }
    }
    
    
    // MARK: BTNS Pushed
    @IBAction func btnPercentsPushed(_ sender: UIButton) {
        downState = .percents
        picker.reloadAllComponents()
        if let index = percents.firstIndex(of: percent) {
            picker.selectRow(index, inComponent: 0, animated: true)
        }
        
        movePickerUp()
    }
    
    
    @IBAction func btnFrequencyPushed(_ sender: Any) {
        downState = .frequency
        picker.reloadAllComponents()
        if let index = frequencys.firstIndex(of: frequency) {
            picker.selectRow(index, inComponent: 0, animated: true)
        }
        movePickerUp()
    }
    
    
    @IBAction func btnTimePushed(_ sender: Any) {
        downState = .time
        picker.reloadAllComponents()
        picker.selectRow(timeFrom, inComponent: 0, animated: true)
        picker.selectRow(timeTo, inComponent: 1, animated: true)
        movePickerUp()
    }
    
    
    
    @IBAction func switcherChanged(_ sender: Any) {
        func runByCellsSwithcers(flag: Bool) {
            for c in tblView.visibleCells {
                if let c = c as? MyCell {
                    c.switcher.setOn(flag, animated: true)
                    try! realm.write {
                        c.note?.isOn = flag
                    }
                }
            }
            
        }
    
        runByCellsSwithcers(flag: switcher.isOn)
        refreshNotifications()
        tblView.reloadData()
    }
    
    func checkAllSwitchersOff() {
        switcher.isOn = false
        for n in notesDataSource {
            if n.isOn {
                switcher.isOn = true
                break
            }
        }
    }
    
    private func readUserDefaults() {
        if let fr = userDefaults.object(forKey: "frequency") as? Int64 {
            frequency = Duration.seconds(fr)
        }
        if let tFrom = userDefaults.object(forKey: "timeFrom") as? Int,
            let tTo = userDefaults.object(forKey: "timeTo") as? Int {
                timeFrom = tFrom
                timeTo = tTo
        }
        if let prc = userDefaults.object(forKey: "percent") as? Int {
            percent = prc
        }
    }
    
    private func setBtnTitles() {
        setBtnPercentTitle()
        setBtnFrequencyTitle()
        setBtnTimeTitle()
    }
    
    private func setBtnPercentTitle() {
        btnPercents.setTitle("\(percent)%", for: .normal)
    }
    
    private func setBtnFrequencyTitle() {
        let format = frequency.formatted(
             .units(allowed: [.hours, .minutes],
                    width: .abbreviated))
        btnFreqency.setTitle(format, for: .normal)
    }
    
    private func setBtnTimeTitle() {
        btnTime.setTitle("\(timeFrom):00 - \(timeTo):00", for: .normal)
    }
    
    private func createNotification(date: Date, note: Note) {
        let content = UNMutableNotificationContent()
        var timesText = ""
        if let n1 = note.n1, let n2 = note.n2 {
            let times = Int.random(in: n1...n2)
            timesText = " \(times) times"
        }
        content.body = "\(note.text)" + timesText
        content.sound = .defaultCritical
//        content.sound = UNNotificationSound(named:UNNotificationSoundName(rawValue: "workagan.mp3"))
        
        let dateMatching = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                           from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: false)
        
        let id = "MyRemainder\(dateMatching.year!)\(dateMatching.month!)\(dateMatching.day!)\(dateMatching.hour!)\(dateMatching.minute!)"
        print(id)
        let request = UNNotificationRequest(identifier: id ,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if error != nil {
                print("Something went wrong with Notification")
            }
        })
    }
    
    func refreshNotifications() {
        let notifCenter = UNUserNotificationCenter.current()
        notifCenter.removeAllDeliveredNotifications()
        notifCenter.removeAllPendingNotificationRequests()
        
        let currentDateTime = Date()
        let iii = Calendar.current.dateComponents([.hour, .minute], from: currentDateTime)
        
        var newDate = Calendar.current.date(bySettingHour: iii.hour!, minute: iii.minute!, second: 0, of: currentDateTime)!
        
        let activeNotes = notesDataSource.filter({ $0.isOn })
        if activeNotes.count > 0 {
            for _ in 0..<24 {
                newDate = newDate.addingTimeInterval(60 /* * 60*/)
//                if Calendar.current.dateComponents([.hour], from: newDate).hour! > 21 {
//                    newDate = newDate.addingTimeInterval(60 * 60 * 11)
//                }
                
                if Int.random(in: 0..<100) < 100 {
                    let randomNote = activeNotes[Int.random(in: 0..<activeNotes.count)]
                    createNotification(date: newDate, note: randomNote)
                }
            }
        }
    }
    
    func fillPersents(step: Int) {
        var x = step
        while x <= 100 {
            percents.append(x)
            x += step
        }
    }
    
    func saveToUD() {
        userDefaults.setValue(percent, forKey: "percent")
        userDefaults.setValue(frequency.components.seconds, forKey: "frequency")
        userDefaults.setValue(timeFrom, forKey: "timeFrom")
        userDefaults.setValue(timeTo, forKey: "timeTo")
    }
}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notesDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "myCell") as? MyCell {
            cell.note = notesDataSource[indexPath.row]
            cell.delegate = self
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let removingNote = notesDataSource.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
            try! realm.write {
                realm.delete(removingNote)
            }
            checkAllSwitchersOff()
        }
    }
    
}

extension ViewController: NoteCreator {
    func createNote(txt: String, n1: Int?, n2: Int?) {
        let note = Note()
        note.text = txt
        note.n1 = n1
        note.n2 = n2
        try! realm.write {
            realm.add(note)
        }
        notesDataSource.append(note)
        tblView.reloadData()
        checkAllSwitchersOff()
    }
}


extension ViewController: IsOnDelegate {
    func switchedNote(note: Note, flag: Bool) {
        try! realm.write {
            note.isOn = flag
        }
        checkAllSwitchersOff()
        
        refreshNotifications()
    }
}



// MARK: Support Picker View
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func createSupportPickerView() {
        supportPickerView.frame = CGRect(x: 0,
                                          y: UIScreen.main.bounds.height + 1,
                                          width: UIScreen.main.bounds.width,
                                          height: UIScreen.main.bounds.height * 0.25)
        supportPickerView.backgroundColor = .white
        supportPickerView.layer.zPosition = 10
        
        picker = UIPickerView()
        picker.frame = CGRect(x: 0,
                              y: 0,
                              width: supportPickerView.frame.width * 0.75,
                              height: supportPickerView.frame.height)
        picker.dataSource = self
        picker.delegate = self
        
        supportPickerView.addSubview(picker)
        
        let buttonYes = UIButton()
        buttonYes.frame = CGRect(x: picker.frame.maxX,
                                 y: 0,
                                 width: supportPickerView.frame.width * 0.25,
                                 height: supportPickerView.frame.height + 1)
        buttonYes.setTitle("Close", for: .normal)
        buttonYes.addTarget(self, action: #selector(movePickerDown), for: .touchUpInside)
        buttonYes.layer.borderWidth = 1
        buttonYes.layer.borderColor = UIColor.black.cgColor
        buttonYes.setTitleColor(.black, for: .normal)
        supportPickerView.addSubview(buttonYes)
        
        let balkaView = UIView()
        balkaView.frame = CGRect(origin: CGPoint(x: 0, y: 0),
                                 size: CGSize(width: supportPickerView.frame.width,
                                               height: 1))
        balkaView.backgroundColor = .black
        supportPickerView.addSubview(balkaView)
        
        self.view.addSubview(supportPickerView)
    }
    
    func movePickerUp() {
        UIView.animate(withDuration: 0.3,
                       animations: { [weak self] in
            self?.supportPickerView.frame = CGRect(x: 0,
                                             y: UIScreen.main.bounds.height * 0.68,
                                             width: UIScreen.main.bounds.width,
                                             height: UIScreen.main.bounds.height * 0.25)
        })
    }
    
    @objc func movePickerDown() {
        UIView.animate(withDuration: 0.3,
                       animations: { [weak self] in
            self?.supportPickerView.frame = CGRect(x: 0,
                                                   y: UIScreen.main.bounds.height + 1,
                                                   width: UIScreen.main.bounds.width,
                                                   height: UIScreen.main.bounds.height * 0.25)
        })
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return downState == .time ? 2 : 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch downState {
        case .percents:
            return percents.count
        case .frequency:
            return frequencys.count
        case .time:
            return 24
        default: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch downState {
        case .percents:
            return "\(percents[row])%"
        case .frequency:
            let format = frequencys[row].formatted(
                 .units(allowed: [.hours, .minutes],
                        width: .wide))
            return format
        case .time:
            return "\(row):00"
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if downState == .percents {
            btnPercents.configuration?.image = nil
            percent = (row + 1) * 5
            setBtnPercentTitle()
        } else if downState == .frequency {
            btnFreqency.configuration?.image = nil
            frequency = frequencys[row]
            setBtnFrequencyTitle()
        } else if downState == .time {
            if component == 0 {
                timeFrom = row
            } else if component == 1 {
                timeTo = row
            }
            setBtnTimeTitle()
        }
        saveToUD()
    }
}
