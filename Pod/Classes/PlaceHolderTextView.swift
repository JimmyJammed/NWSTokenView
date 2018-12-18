//
//  UIPlaceHolderTextView.swift
//  NWSTokenView
//
//  Created by Phanha Uy on 12/18/18.
//
/*
 Copyright (c) 2015 Appmazo, LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.//
 */

import UIKit

class PlaceHolderTextView: UITextView, UITextViewDelegate {
    
    var placeholderText: String? {
        didSet {
            self.placeholder = placeholderText
        }
    }
    
    var textViewDelegate: UITextViewDelegate?
    
    /// When the UITextView did change, show or hide the label based on if the UITextView is empty or not
    ///
    /// - Parameter textView: The UITextView that got updated
    private func textViewDidChange(_ textView: UITextView) {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = self.text.count > 0
        }
        
        self.textViewDelegate?.textViewDidChange!(textView)
    }
}

/// Extend UITextView and implemented UITextViewDelegate to listen for changes
extension UITextView {
    
    /// Resize the placeholder when the UITextView bounds change
    override open var bounds: CGRect {
        didSet {
            if #available(iOS 9.0, *) {
                return
            }
            self.resizePlaceholder()
        }
    }
    
    /// Resize the placeholder when the UITextView frame change
    override open var frame: CGRect {
        didSet {
            if #available(iOS 9.0, *) {
                return
            }
            self.resizePlaceholder()
        }
    }
    
    /// The UITextView placeholder text
    var placeholder: String? {
        get {
            var placeholderText: String?
            
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeholderLabel.text
            }
            
            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                guard let placeHolder = newValue else {
                    return
                }
                self.addPlaceholder(placeHolder)
            }
        }
    }
    
    /// Resize the placeholder UILabel to make sure it's in the same position as the UITextView text
    fileprivate func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
            let labelX = self.textContainer.lineFragmentPadding + self.textContainerInset.left
            let labelY = self.textContainerInset.top
            
            let labelWidth = self.frame.width - (labelX * 2)
            let labelheight = placeholderLabel.frame.height
            
            placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelheight)
        }
    }
    
    /// Adds a placeholder UILabel to this UITextView
    fileprivate func addPlaceholder(_ placeholderText: String) {
        let placeholderLabel = UILabel()
        
        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()
        
        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.tag = 100
        placeholderLabel.numberOfLines = 0
        
        placeholderLabel.isHidden = self.text.count > 0
        
        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
        
        self.delegate = self as? UITextViewDelegate
    }
    
    fileprivate func refreshPlaceholder(_ placeholderLabel: UILabel?) {
        placeholderLabel?.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 9.0, *) {
            placeholderLabel?.leftAnchor.constraint(equalTo: self.leftAnchor, constant: textContainerInset.left + self.textContainer.lineFragmentPadding).isActive = true
            placeholderLabel?.rightAnchor.constraint(equalTo: self.rightAnchor, constant: textContainerInset.right + self.textContainer.lineFragmentPadding).isActive = true
            placeholderLabel?.topAnchor.constraint(equalTo: self.topAnchor, constant: textContainerInset.top).isActive = true
            placeholderLabel?.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: textContainerInset.bottom)
        } else {
            // Fallback on earlier versions
            self.resizePlaceholder()
        }
    }
}
