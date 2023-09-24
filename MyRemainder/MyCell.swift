//
//  MyCell.swift
//  MyRemainder
//
//  Created by Yura on 21.09.2023.
//

import UIKit

class MyCell: UITableViewCell {

    @IBOutlet weak var switcher: UISwitch!
    @IBOutlet weak var lbl: UILabel!
    var delegate: IsOnDelegate? = nil
    
    var note: Note? {
        didSet {
            var dopText = ""
            if let n1 = note?.n1, let n2 = note?.n2 {
                dopText = "  from \(n1) to \(n2) times"
            }
            lbl.text = (note?.text ?? "") + dopText
            switcher.isOn = note?.isOn  ?? true
        }
    }
    
    @IBAction func switcherChanged(_ sender: UISwitch) {
        if let note = note {
            delegate?.switchedNote(note: note, flag: switcher.isOn)
        }
    }
    
}
