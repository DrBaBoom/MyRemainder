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
    
    @IBOutlet var tblView: UITableView!
    @IBOutlet weak var switcher: UISwitch!
    
    var notesDataSource: [Note] = []
    var realm: Realm!


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
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        
        let dateMatching = Calendar.current.dateComponents([.year, .month, .day, .hour],
                                                           from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: false)
        
        let id = "MyRemainder\(dateMatching.year!)\(dateMatching.month!)\(dateMatching.day!)\(dateMatching.hour!)"
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
        let iii = Calendar.current.dateComponents([.hour], from: currentDateTime)
        
        var newDate = Calendar.current.date(bySettingHour: iii.hour!, minute: 0, second: 0, of: currentDateTime)!
        
        let activeNotes = notesDataSource.filter({ $0.isOn })
        if activeNotes.count > 0 {
            for _ in 0..<300 {
                newDate = newDate.addingTimeInterval(60 * 60)
                
                if Calendar.current.dateComponents([.hour], from: newDate).hour! > 21 {
                    newDate = newDate.addingTimeInterval(60 * 60 * 11)
                }
                
                if Int.random(in: 0..<100) < 30 {
                    let randomNote = activeNotes[Int.random(in: 0..<activeNotes.count)]
                    createNotification(date: newDate, note: randomNote)
                }
            }
        }
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
