//
//  KAPinField.swift
//  KAPinCode
//
//  Created by Alexis Creuzot on 15/10/2018.
//  Copyright © 2018 alexiscreuzot. All rights reserved.
//

import UIKit

// Mark: - KAPinFieldDelegate
public protocol KAPinFieldDelegate {
    func ka_pinField(_ field: KAPinField, didFinishWith code: String)
}

// Mark: - KAPinField Class
public class KAPinField : UITextField {
    
    // Mark: - Public vars
    public var ka_delegate : KAPinFieldDelegate? = nil
    
    public var ka_numberOfCharacters: Int = 4 {
        didSet {
            precondition(ka_numberOfCharacters >= 1, "Number of character must be >= 1")
            self.setupUI()
        }
    }
    public var ka_validCharacters: String = "0123456789" {
        didSet {
            precondition(ka_validCharacters.count > 0, "There must be at least 1 valid character")
            precondition(!ka_validCharacters.contains(ka_token), "Valid characters can't contain token \"\(ka_token)\"")
            self.setupUI()
        }
    }
    public var ka_text : String {
        get { return invisibleText }
        set {
            self.invisibleField.text = newValue
            self.refreshUI()
        }
    }
    public var ka_font : KA_MonospacedFont? = .menlo(40){
        didSet{
            self.setupUI()
        }
    }
    public var ka_token: Character = "•" {
        didSet {
            precondition(!ka_validCharacters.contains(ka_token), "Valid characters can't contain token \"\(ka_token)\"")
            self.setupUI()
        }
    }
    public var ka_tokenColor : UIColor? {
        didSet {
            self.setupUI()
        }
    }
    public var ka_textColor : UIColor? {
        didSet {
            self.setupUI()
        }
    }
    public var ka_kerning : CGFloat = 16.0 {
        didSet {
            self.setupUI()
        }
    }
    
    // Mark: - Overriden vars
    public override var font: UIFont? {
        didSet{
            self.ka_font = nil
        }
    }
    
    // Mark: - Private vars
    
    // Uses an invisible UITextField to handle text
    // this is necessary for iOS12 .oneTimePassword feature
    private var invisibleField = UITextField()
    private var invisibleText : String {
        get {
            return invisibleField.text ?? ""
        }
        set {
            self.refreshUI()
        }
    }
    
    // Mark: - Lifecycle
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.bringSubviewToFront(self.invisibleField)
        self.invisibleField.frame = self.bounds
    }
    
    private func setupUI() {
        
        // Change this for easy debug
        let alpha: CGFloat = 0.0
        self.invisibleField.backgroundColor =  UIColor.white.withAlphaComponent(alpha * 0.8)
        self.invisibleField.tintColor = UIColor.black.withAlphaComponent(alpha)
        self.invisibleField.textColor = UIColor.black.withAlphaComponent(alpha)
        
        // Prepare `invisibleField`
        self.invisibleField.text = ""
        self.invisibleField.keyboardType = .numberPad
        self.invisibleField.textAlignment = .center
        if #available(iOS 12.0, *) {
            // Show possible prediction on iOS >= 12
            self.invisibleField.textContentType = .oneTimeCode
            self.invisibleField.autocorrectionType = .yes
        }
        self.addSubview(self.invisibleField)
        self.invisibleField.addTarget(self, action: #selector(refreshUI), for: .allTouchEvents)
        self.invisibleField.addTarget(self, action: #selector(refreshUI), for: .editingChanged)
        
        // Prepare visible field
        self.tintColor = .clear // Hide cursor
        
        // Delay fixes kerning offset issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.refreshUI()
        }
    }
    
    // Mark: - Public functions
    
    override public func becomeFirstResponder() -> Bool {
        return self.invisibleField.becomeFirstResponder()
    }
    
    override public func resignFirstResponder() -> Bool {
        return self.invisibleField.resignFirstResponder()
    }
    
    public func ka_animateFailure(_ completion : (() -> Void)? = nil) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            completion?()
        })
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.repeatCount = 3
        animation.duration = CFTimeInterval(0.2 / animation.repeatCount)
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 8, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 8, y: self.center.y))
        self.layer.add(animation, forKey: "position")
        
        CATransaction.commit()
    }
    
    public func ka_animateSuccess(with text: String, completion : (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.alpha = 0
        }) { _ in
            self.text = text
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = CGAffineTransform.identity
                self.alpha = 1.0
            }) { _ in
                completion?()
            }
        }
    }
    
    // Mark: - Private function
    
    // Updates textfield content
    @objc private func refreshUI() {
        
        self.sanitizeText()
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let font =  self.ka_font?.font() ?? self.font ?? UIFont.preferredFont(forTextStyle: .headline)
        var attributes: [NSAttributedString.Key : Any] = [ .paragraphStyle : paragraph,
                                                           .font : font,
                                                           .kern : self.ka_kerning]
        
        // Display
        let attString = NSMutableAttributedString(string: "")
        for i in 0..<ka_numberOfCharacters {
            
            var string = ""
            if i < invisibleText.count {
                let index = invisibleText.index(string.startIndex, offsetBy: i)
                string = String(invisibleText[index])
            } else {
                string = String(ka_token)
            }
            
            // Color
            if string == String(ka_token) {
                attributes[.foregroundColor] = self.ka_tokenColor
            } else {
                attributes[.foregroundColor] = self.ka_textColor
            }
            
            // Fix kerning-centering
            if i == ka_numberOfCharacters - 1 {
                attributes[.kern] = 0.0
            }
            
            attString.append(NSAttributedString(string: string, attributes: attributes))
        }
        
        self.attributedText = attString
        
        if #available(iOS 11.0, *) {
            self.updateCursorPosition()
        }
        self.checkCodeValidity()
    }
    
    private func sanitizeText() {
        var text = self.invisibleField.text ?? ""
        text = String(text.lazy.filter(ka_validCharacters.contains))
        text = String(text.prefix(self.ka_numberOfCharacters))
        self.invisibleField.text = text
    }
    
    // Always position cursor on last valid character
    private func updateCursorPosition() {
        let offset = min(self.invisibleText.count, ka_numberOfCharacters)
        // Only works with a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if let position = self.invisibleField.position(from: self.invisibleField.beginningOfDocument, offset: offset) {
                self.invisibleField.selectedTextRange = self.textRange(from: position, to: position)
            }
        }
    }
    
    private func checkCodeValidity() {
        if self.invisibleText.count == self.ka_numberOfCharacters {
            if let pindDelegate = self.ka_delegate {
                pindDelegate.ka_pinField(self, didFinishWith: self.invisibleText)
            } else {
                print("warning : No pinDelegate set for KAPinField")
            }
        }
    }
}

// Mark: - KA_MonospacedFont
// Helper to provide monospaced fonts via literal
public enum KA_MonospacedFont {
    
    case courier(CGFloat)
    case courierBold(CGFloat)
    case courierBoldOblique(CGFloat)
    case courierOblique(CGFloat)
    case courierNewBoldItalic(CGFloat)
    case courierNewBold(CGFloat)
    case courierNewItalic(CGFloat)
    case courierNew(CGFloat)
    case menloBold(CGFloat)
    case menloBoldItalic(CGFloat)
    case menloItalic(CGFloat)
    case menlo(CGFloat)
    
    func font() -> UIFont {
        switch self {
        case .courier(let size) :
            return UIFont(name: "Courier", size: size)!
        case .courierBold(let size) :
            return UIFont(name: "Courier-Bold", size: size)!
        case .courierBoldOblique(let size) :
            return UIFont(name: "Courier-BoldOblique", size: size)!
        case .courierOblique(let size) :
            return UIFont(name: "Courier-Oblique", size: size)!
        case .courierNewBoldItalic(let size) :
            return UIFont(name: "CourierNewPS-BoldItalicMT", size: size)!
        case .courierNewBold(let size) :
            return UIFont(name: "CourierNewPS-BoldMT", size: size)!
        case .courierNewItalic(let size) :
            return UIFont(name: "CourierNewPS-ItalicMT", size: size)!
        case .courierNew(let size) :
            return UIFont(name: "CourierNewPSMT", size: size)!
        case .menloBold(let size) :
            return UIFont(name: "Menlo-Bold", size: size)!
        case .menloBoldItalic(let size) :
            return UIFont(name: "Menlo-BoldItalic", size: size)!
        case .menloItalic(let size) :
            return UIFont(name: "Menlo-Italic", size: size)!
        case .menlo(let size) :
            return UIFont(name: "Menlo-Regular", size: size)!
        }
    }
}
