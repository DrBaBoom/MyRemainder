//
//  Task_VC.swift
//  MyRemainder
//
//  Created by Yura on 21.09.2023.
//

import UIKit


class Task_VC: UIViewController {

    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var txtField1: UITextField!
    @IBOutlet weak var txtField2: UITextField!
    @IBOutlet weak var btnSave: UIButton!
    
    var delegate: NoteCreator? = nil
    
    override var sheetPresentationController: UISheetPresentationController {
        presentationController as! UISheetPresentationController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        sheetPresentationController.delegate = self
        sheetPresentationController.selectedDetentIdentifier = .medium
        sheetPresentationController.prefersGrabberVisible = true
        sheetPresentationController.detents = [.medium(), .large()]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        txtView.addDoneButton()
        txtField1.addDoneButton()
        txtField2.addDoneButton()
    }
    
    
    @IBAction func btnSavePushed(_ sender: Any) {
        if let delegate = delegate, txtView.text != nil, txtView.text != "" {
            var txtInt1 = ""
            var txtInt2 = ""
            if txtField1.text != "", txtField2.text != "" {
                txtInt1 = txtField1.text!
                txtInt2 = txtField2.text!
            }
            delegate.createNote(txt: txtView.text, n1: Int(txtInt1), n2: Int(txtInt2))
            dismiss(animated: true, completion: nil)
        }
    }
    
}


extension Task_VC: UISheetPresentationControllerDelegate {
    
}


