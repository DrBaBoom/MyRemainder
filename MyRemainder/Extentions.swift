//
//  Extentions.swift
//  MyRemainder
//
//  Created by Yura on 21.09.2023.
//

import Foundation
import UIKit


extension UITextView {
    func addDoneButton() {
        let doneToolBar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolBar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolBar.items = items
        doneToolBar.sizeToFit()
        
        self.inputAccessoryView = doneToolBar
    }
    
    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
}


extension UITextField {
    func addDoneButton() {
        let doneToolBar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolBar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolBar.items = items
        doneToolBar.sizeToFit()
        
        self.inputAccessoryView = doneToolBar
    }
    
    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
}


extension Duration {
    static func minutes(_ m: any BinaryInteger) -> Duration {
        Duration.seconds(Int(m) * 60)
    }
    
    static func hours(_ h: any BinaryInteger) -> Duration {
        Duration.minutes(Int(h) * 60)
    }
    
}
