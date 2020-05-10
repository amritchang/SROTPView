//
//  SROTPView.swift
//  SROTPView
//
//  Created by admin on 11/20/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit


class SROTPView: UIView {
    
    let otpStackView = OTPStackView()
    public var otpEnteredString :((String)->())?
    var otpTextFieldsCount = 6{
        didSet{
            otpStackView.otpTextFieldsCount = self.otpTextFieldsCount
        }
    }
    var secureEntry = false
    
    
    func setUpUI(){
        otpStackView.secureEntry = self.secureEntry
        self.addSubview(otpStackView)
        otpStackView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        otpStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        otpStackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        otpStackView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        otpStackView.otpEnteredString = {value in
            (self.otpEnteredString?(value))
        }
    }
    
    func setUpOtpView(){
        setUpUI()
        otpStackView.addOTPFields()
        let topView = UIView()
        topView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        topView.backgroundColor = UIColor.clear
        topView.isUserInteractionEnabled = true
        self.addSubview(topView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(getResponder))
        tapGesture.numberOfTapsRequired = 1
        topView.addGestureRecognizer(tapGesture)
        
    }
    
    func initializeUI(){
        otpStackView.refreshView()
    }
    
    //MARK:Get Touch event when touch on view
    @objc func getResponder(){
        otpStackView.assignResponder()
    }
    
    func set(warning:Bool){
        self.otpStackView.transform = CGAffineTransform(translationX: 20, y: 0)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 10, options: .curveLinear, animations: {
            self.otpStackView.transform = CGAffineTransform.identity
            self.otpStackView.setWarningColor(isWarningColor: true)
        }) { _ in
            self.otpStackView.transform = CGAffineTransform.identity
        }
        
    }
    
}


class OTPStackView: UIStackView {
    //Customise the OTPField here
    var otpTextFieldsCount = 6{
        didSet{
            self.addOTPFields()
        }
    }
    var textFieldsCollection: [OTPTextField] = []
    var showsWarningColor = false
    var activeTextField:OTPTextField?
    var hasEnteredAllOTP = false
    var space: CGFloat = 28
    var size: CGFloat = 50
    var otpTextFieldFontColor = UIColor.white
    var otpTextFieldErrorColor = UIColor.red
    
    var activeHeight = 2
    var inactiveHeight = 2
    var secureEntry = false
    //Colors
    let otpTextFieldDefaultBorderColor = UIColor.white
    let textBackgroundColor = UIColor.clear
    let otpTextFieldActiveBorderColor = UIColor.white
    public var otpEnteredString :((String)->())?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }
    
    //Customisation and setting stackView
    func setupStackView() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentMode = .center
        self.distribution = .equalSpacing
        self.spacing = space
        if (CGFloat(otpTextFieldsCount - 1)*space + CGFloat(otpTextFieldsCount)*size) > self.bounds.size.width{
            self.spacing = (self.bounds.size.width - CGFloat(otpTextFieldsCount)*size) / (CGFloat(otpTextFieldsCount - 1))
        }
        
    }
    
    //Adding each OTPfield to stack view
    func addOTPFields() {
        self.textFieldsCollection = []
        for each in self.subviews{
            each.removeFromSuperview()
        }
        for index in 0..<otpTextFieldsCount{
            let field = OTPTextField()
            field.tag = index
            setupTextField(field)
            textFieldsCollection.append(field)
            //Adding a marker to previous field
            index != 0 ? (field.previousTextField = textFieldsCollection[index-1]) : (field.previousTextField = nil)
            //Adding a marker to next field for the field at index-1
            index != 0 ? (textFieldsCollection[index-1].nextTextField = field) : ()
        }
        
        activeTextField = textFieldsCollection[0]
    }
    
    func assignResponder(){
        DispatchQueue.main.async {
            self.activeTextField?.becomeFirstResponder()
        }
    }
    
    //Customisation and setting OTPTextFields
    func setupTextField(_ textField: OTPTextField){
        textField.delegate = self
        textField.textContentType = .none
        //Adding constraints wrt to its parent i.e OTPStackView
        textField.translatesAutoresizingMaskIntoConstraints = false
        self.addArrangedSubview(textField)
        textField.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        textField.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        textField.widthAnchor.constraint(equalToConstant: size).isActive = true
        if secureEntry{
            textField.isSecureTextEntry = true
        }else{
            textField.isSecureTextEntry = false
        }
        textField.backgroundColor = textBackgroundColor
        textField.textAlignment = .center
        textField.adjustsFontSizeToFitWidth = false
        textField.font = UIFont.systemFont(ofSize: 24)
        textField.textColor = otpTextFieldFontColor
        textField.keyboardType = .numberPad
        textField.addborder(color: otpTextFieldDefaultBorderColor,height: CGFloat(inactiveHeight))
    }
    
    func refreshView(){
        for fields in textFieldsCollection{
            fields.text = ""
            hasEnteredAllOTP = false
            (otpEnteredString?(""))
        }
        DispatchQueue.main.async {
            self.textFieldsCollection[0].becomeFirstResponder()
        }
        activeTextField = textFieldsCollection[0]
    }
    
    //checks if all the OTPfields are filled
    func checkForValidity(){
        for fields in textFieldsCollection{
            if (fields.text == ""){
                hasEnteredAllOTP = false
                (otpEnteredString?(self.getOTP()))
                return
            }
        }
        hasEnteredAllOTP = true
        (otpEnteredString?(self.getOTP()))
    }
    
    //gives the OTP text
    func getOTP() -> String {
        var OTP = ""
        for textField in textFieldsCollection{
            OTP += textField.text ?? ""
        }
        return OTP
    }
    
    //set isWarningColor true for using it as a warning color
    func setWarningColor(isWarningColor: Bool = false){
        if isWarningColor{
            for textField in textFieldsCollection{
                textField.changeToErrorBorder(color: otpTextFieldErrorColor, height: 2)
            }
        }else{
            for textField in textFieldsCollection{
                textField.changeToInActiveBorder(color: otpTextFieldDefaultBorderColor,height:CGFloat(inactiveHeight))
            }
        }
        showsWarningColor = isWarningColor
    }
    
}

//TextField related operations
extension OTPStackView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if showsWarningColor {
            setWarningColor(isWarningColor: false)
            showsWarningColor = false
        }
        if let field = textField as? OTPTextField{
            field.changeToActiveBorder(color: otpTextFieldActiveBorderColor,height: CGFloat(activeHeight))
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let field = textField as? OTPTextField{
            field.changeToInActiveBorder(color: otpTextFieldDefaultBorderColor,height:CGFloat(inactiveHeight))
        }
    }
    
    //switches between OTPTextfields
    func textField(_ textField: UITextField, shouldChangeCharactersIn range:NSRange, replacementString string: String) -> Bool {
        let replacedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
        guard let textField = textField as? OTPTextField else { return true }
       
        if !replacedText.isEmpty &&  replacedText.rangeOfCharacter(from: .decimalDigits) == nil {
            return false
        }
        
        if (range.length == 0){
            if  replacedText == ""{
                activeTextField = textFieldsCollection[0]
                activeTextField?.becomeFirstResponder()
                return false
            }
            if textField.nextTextField == nil {
                activeTextField = textField
                DispatchQueue.main.async {
                    textField.resignFirstResponder()
                }
            }else{
                textField.nextTextField?.becomeFirstResponder()
                activeTextField = textField.nextTextField
            }
            textField.text? = string
            checkForValidity()
            return false
                       
        }else if (range.length == 1) {
                    textField.previousTextField?.becomeFirstResponder()
                    if textField.previousTextField != nil{
                        activeTextField = textField.previousTextField
                    }
                    textField.text? = ""
                    checkForValidity()
                    return false
        }
        return false
    }
    
}



