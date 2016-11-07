//
//  NWSTokenView.swift
//  NWSTokenView
//
//  Created by James Hickman on 8/11/15.
/*
Copyright (c) 2015 NitWit Studios, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.//
*/

import UIKit

// MARK: NWSTokenDataSource Protocols
public protocol NWSTokenDataSource
{
    func insetsForTokenView(_ tokenView: NWSTokenView) -> UIEdgeInsets?
    func numberOfTokensForTokenView(_ tokenView: NWSTokenView) -> Int
    func titleForTokenViewLabel(_ tokenView: NWSTokenView) -> String?
    func titleForTokenViewPlaceholder(_ tokenView: NWSTokenView) -> String?
    func tokenView(_ tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView?
}

// MARK: NWSTokenDelegate Protocols
public protocol NWSTokenDelegate
{
    func tokenView(_ tokenView: NWSTokenView, didSelectTokenAtIndex index: Int)
    func tokenView(_ tokenView: NWSTokenView, didDeselectTokenAtIndex index: Int)
    func tokenView(_ tokenView: NWSTokenView, didDeleteTokenAtIndex index: Int)
    func tokenView(_ tokenViewDidBeginEditing: NWSTokenView)
    func tokenViewDidEndEditing(_ tokenView: NWSTokenView)
    func tokenView(_ tokenView: NWSTokenView, didChangeText text: String)
    func tokenView(_ tokenView: NWSTokenView, didEnterText text: String)
    func tokenView(_ tokenView: NWSTokenView, contentSizeChanged size: CGSize)
    func tokenView(_ tokenView: NWSTokenView, didFinishLoadingTokens tokenCount: Int)
}

// MARK: NWSTokenView Class
open class NWSTokenView: UIView, UIScrollViewDelegate, UITextViewDelegate
{
    @IBInspectable open var dataSource: NWSTokenDataSource? = nil
    @IBInspectable open var delegate: NWSTokenDelegate? = nil
    
    // MARK: Private Vars
    fileprivate var shouldBecomeFirstResponder: Bool = false
    fileprivate var scrollView = UIScrollView()
    open var textView = UITextView()
    fileprivate var lastTokenCount = 0
    fileprivate var lastText = ""
    
    // MARK: Public Vars
    var label = UILabel()
    var tokens: [NWSToken] = []
    var selectedToken: NWSToken?
    var tokenViewInsets: UIEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5) // Default
    var tokenHeight: CGFloat = 30.0 // Default
    var didReloadFromRotation = false
    
    // MARK: Constants
    var labelMinimumHeight: CGFloat = 30.0
    var labelMinimumWidth: CGFloat = 30.0
    var textViewMinimumWidth: CGFloat = 30.0
    var textViewMinimumHeight: CGFloat = 30.0
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update scroll view content size
        let contentSize = self.scrollView.contentSize
        self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.width, height: contentSize.height)
    }
    
    override open func awakeFromNib()
    {
        super.awakeFromNib()

        // Set default scroll properties
        self.scrollView.backgroundColor = UIColor.clear
        self.scrollView.isScrollEnabled = true
        self.scrollView.isUserInteractionEnabled = true
        self.scrollView.autoresizesSubviews = false
        self.addSubview(self.scrollView)
        
        // Set default label properties
        self.label.font = UIFont(name: "HelveticaNeue", size: 14)
        self.label.textColor = UIColor.black
        
        // Set default text view properties
        self.textView.backgroundColor = UIColor.clear
        self.textView.textColor = UIColor.black
        self.textView.font = UIFont(name: "HelveticaNeue", size: 14)
        self.textView.delegate = self
        self.textView.isScrollEnabled = false
        self.textView.autocorrectionType = UITextAutocorrectionType.no // Hide suggestions to prevent UI issues with message bar / keyboard.
        self.scrollView.addSubview(self.textView)
        
        // Auto Layout Constraints
        self.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0).isActive = true

        // Orientation Rotation Listener
        NotificationCenter.default.addObserver(self, selector: #selector(NWSTokenView.didRotateInterfaceOrientation), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    /// Reloads data when interface orientation is changed.
    func didRotateInterfaceOrientation()
    {
        // Ignore "flat" orientation
        if UIDevice.current.orientation == UIDeviceOrientation.faceUp || UIDevice.current.orientation == UIDeviceOrientation.faceDown || UIDevice.current.orientation == UIDeviceOrientation.unknown
        {
            return
        }
        
        // Prevent keyboard from hiding on rotation due to reloadData called from delegate
        if self.textView.isFirstResponder
        {
            self.shouldBecomeFirstResponder = true
        }
        
        // Save rotation flag (for use with selected tokens)
        self.didReloadFromRotation = true
        
        self.reloadData()
    }
    
    /// Reloads data from datasource and delegate implementations.
    open func reloadData()
    {
        UIView.setAnimationsEnabled(false) // Disable animation to fix flicker of token text
        
        // Reset
        self.resetTokenView()
        
        // Update Insets from delegate
        if let insets = dataSource?.insetsForTokenView(self)
        {
            self.tokenViewInsets = insets
        }
        
        // Set origins
        var scrollViewOriginX: CGFloat = self.tokenViewInsets.left
        var scrollViewOriginY: CGFloat = self.tokenViewInsets.top
        
        // Track remaining width
        var remainingWidth = self.scrollView.bounds.width
        
        // Add label
        self.setupLabel(offsetX: &scrollViewOriginX, offsetY: &scrollViewOriginY, remainingWidth:&remainingWidth)
        
        // Add Tokens
        let numOfTokens: Int = (dataSource?.numberOfTokensForTokenView(self))!
        for index in 0..<numOfTokens {
            if var token = dataSource?.tokenView(self, viewForTokenAtIndex: index) as? NWSToken
            {
                self.setupToken(&token, atIndex: index, withOffsetX: &scrollViewOriginX, withOffsetY: &scrollViewOriginY, remainingWidth: &remainingWidth)
            }
        }
        
        // Add TextView
        self.setupTextView(offsetX: &scrollViewOriginX, offsetY: &scrollViewOriginY, remainingWidth: &remainingWidth)
        
        // Update scroll view content size
        if self.tokens.count > 0
        {
            self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.width, height: scrollViewOriginY+max(textViewMinimumHeight, self.tokenHeight)+self.tokenViewInsets.top)
        }
        else
        {
            self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.width, height: scrollViewOriginY+textViewMinimumHeight+self.tokenViewInsets.top)
        }
        
        // Scroll to bottom if added new token, otherwise stay in current position
        if self.tokens.count > self.lastTokenCount
        {
            self.shouldBecomeFirstResponder = true
            self.scrollToBottom(animated: false)
        }
        self.lastTokenCount = self.tokens.count
        
        // Restore text
        if self.lastText != ""
        {
            self.textView.text = self.lastText
            self.lastText = ""
        }
        
        // Check if text view should become first responder (i.e. new token added)
        if self.shouldBecomeFirstResponder
        {
            self.textView.becomeFirstResponder()
            self.shouldBecomeFirstResponder = false
        }
        
        // Reset Rotation Flag
        self.didReloadFromRotation = false
        
        // Notify delegate of content size change
        self.delegate?.tokenView(self, contentSizeChanged: self.scrollView.contentSize)
        
        // Notify delegate of finished loading
        self.delegate?.tokenView(self, didFinishLoadingTokens: self.tokens.count)
        
        UIView.setAnimationsEnabled(true) // Re-enable animations
    }
    
    /// Resets token view by removing all scroll view subviews and resetting instance variables
    fileprivate func resetTokenView()
    {
        for token in self.tokens
        {
            token.removeFromSuperview()
        }
        
        self.tokens = []
        self.tokenHeight = 0
        // Ignore placeholder text
        if self.textView.text != self.dataSource?.titleForTokenViewPlaceholder(self)
        {
            self.lastText = self.textView.text
        }
    }
    
    /// Sets up token view label.
    fileprivate func setupLabel(offsetX x: inout CGFloat, offsetY y: inout CGFloat, remainingWidth: inout CGFloat)
    {
        if let labelText = self.dataSource?.titleForTokenViewLabel(self)
        {
            self.label.bounds.size = CGSize(width: self.labelMinimumWidth, height: self.labelMinimumHeight)
            self.label.text = labelText
            self.label.frame = CGRect(x: x, y: y, width: self.label.bounds.width-self.tokenViewInsets.left-self.tokenViewInsets.right, height: self.labelMinimumHeight)
            self.label.sizeToFit()
            // Reset frame after sizeToFit
            self.label.frame = CGRect(x: x, y: y, width: self.label.bounds.width, height: self.labelMinimumHeight)
            self.scrollView.addSubview(self.label)
            x += self.label.bounds.width
            remainingWidth -= x
        }
        
    }
    
    /// Sets up token view text view.
    fileprivate func setupTextView(offsetX x: inout CGFloat, offsetY y: inout CGFloat, remainingWidth: inout CGFloat)
    {
        // Set placeholder text (ignore if tokens exist, text exists, or is currently active field)
        if self.tokens.count == 0 && self.lastText == "" && !self.shouldBecomeFirstResponder
        {
            if let placeholderText = self.dataSource?.titleForTokenViewPlaceholder(self)
            {
                self.textView.text = placeholderText
                self.textView.textColor = UIColor.lightGray
            }
        }
        else
        {
            self.textView.textColor = UIColor.black
            self.textView.text = ""
        }
        
        // Get remaining width on line
        if remainingWidth >= self.textViewMinimumWidth
        {
            self.textView.frame = CGRect(x: x + self.tokenViewInsets.left, y: y, width: remainingWidth - self.tokenViewInsets.left - self.tokenViewInsets.right, height: max(self.textViewMinimumHeight, self.tokenHeight))
            remainingWidth = self.scrollView.bounds.width - x - self.textView.frame.width
        }
        else // Move text view to new line
        {
            // Reset remaining width
            remainingWidth = self.scrollView.bounds.width
            
            // Reset X Offset
            x = 0
            // Increase Y Offset
            y += max(self.textViewMinimumHeight, self.tokenHeight) + self.tokenViewInsets.top
            
            self.textView.frame = CGRect(x: x + self.tokenViewInsets.left, y: y, width: remainingWidth - self.tokenViewInsets.left - self.tokenViewInsets.right, height: max(self.textViewMinimumHeight, self.tokenHeight))
        }
        
        self.textView.returnKeyType = UIReturnKeyType.next
    }
    
    /// Sets up new token.
    fileprivate func setupToken(_ token: inout NWSToken, atIndex index: Int, withOffsetX x: inout CGFloat, withOffsetY y: inout CGFloat, remainingWidth: inout CGFloat)
    {
        // Add to token collection
        self.tokens.append(token)
        
        // Set hidden text view delegate for deselecting
        token.hiddenTextView.delegate = self
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action:#selector(NWSTokenView.didTapToken(_:)))
        token.addGestureRecognizer(tapGesture)
        
        // Add tags for referencing
        token.tag = index
        token.hiddenTextView.tag = index
        
        // Set token height for use with text field
        self.tokenHeight = token.frame.height
        
        // Check if token is out of view's bounds, move to new line if so (unless its first token, truncate it)
        if remainingWidth <= self.tokenViewInsets.left + token.frame.width + self.tokenViewInsets.right && self.tokens.count > 1
        {
            x = 0
            y += token.frame.height + self.tokenViewInsets.top
        }
        token.frame = CGRect(x: x+self.tokenViewInsets.left, y: y, width: min(token.bounds.width, self.scrollView.bounds.width-x-self.tokenViewInsets.left-self.tokenViewInsets.right), height: token.bounds.height)
        
        self.scrollView.addSubview(token)
        
        // Update frame data
        x += self.tokenViewInsets.left + token.frame.width
        remainingWidth = self.scrollView.bounds.width - x
        
        // Check if previously selected (i.e. pre-rotation)
//        if self.selectedToken != nil && self.selectedToken?.titleLabel.text == token.titleLabel.text
//        {
//            self.selectedToken = nil // Reset so selectToken function properly sets token
//            self.selectToken(token)
//        }
    }
    
    /// Returns a generated token.
    ///
    /// - parameter index: Int value for token index.
    ///
    /// - returns: NWSToken
    open func tokenForIndex(_ index: Int) -> NWSToken
    {
        return self.tokens[index]
    }
    
    /// Selects the tapped token for interaction (i.e. removal).
    ///
    /// - parameter tapGesture: UITapGestureRecognizer associated with the token.
    ///
    /// - returns: NWSToken
    open func didTapToken(_ tapGesture: UITapGestureRecognizer)
    {
        let token = tapGesture.view as! NWSToken
        self.selectToken(token)
    }
    
    open func selectToken(_ token: NWSToken)
    {
        // Check if another token is already selected
        if self.selectedToken != nil && self.selectedToken != token
        {
            self.selectedToken?.isSelected = false
            token.hiddenTextView.delegate = nil
            token.hiddenTextView.resignFirstResponder()
            self.delegate?.tokenView(self, didDeselectTokenAtIndex: self.selectedToken!.tag)
        }
        
        token.isSelected = !token.isSelected
        if token.isSelected
        {
            token.hiddenTextView.delegate = self
            token.hiddenTextView.becomeFirstResponder()
            self.selectedToken = token
            self.delegate?.tokenView(self, didSelectTokenAtIndex: token.tag)
        }
        else
        {
            self.selectedToken = nil
            token.hiddenTextView.delegate = nil
            token.hiddenTextView.resignFirstResponder()
            self.delegate?.tokenView(self, didDeselectTokenAtIndex: token.tag)
        }
    }
    
    // UITextView Delegate
    open func textViewDidBeginEditing(_ textView: UITextView)
    {
        // Deselect any tokens
        if self.selectedToken != nil
        {
            self.selectedToken?.isSelected = false
            self.selectedToken?.hiddenTextView.delegate = nil
            self.selectedToken?.hiddenTextView.resignFirstResponder()
            self.delegate?.tokenView(self, didDeselectTokenAtIndex: self.selectedToken!.tag)
            self.selectedToken = nil
        }
        
        // Check if text view is input or hidden
        if textView.superview is NWSToken
        {
            // Do nothing...
        }
        else
        {
            // Replace placeholder text
            if let placeholderText = self.dataSource?.titleForTokenViewPlaceholder(self)
            {
                if textView.text == placeholderText
                {
                    textView.text = ""
                    textView.textColor = UIColor.black
                }
            }
            
        }
        
        // Notify delegate
        self.delegate?.tokenView(self)
    }
    
    open func textViewDidEndEditing(_ textView: UITextView)
    {
        // Check if text view is input or hidden
        if textView.superview is NWSToken
        {
            // Force deselect if another responder is activated
            for (index, token) in self.tokens.enumerated()
            {
                if textView.superview == token
                {
                    self.delegate?.tokenView(self, didDeselectTokenAtIndex: index)
                    // Set selected token to nil if not from rotation (to properly restore selected token after rotation)
                    if !self.didReloadFromRotation
                    {
                        self.selectToken(token)
                    }
                    break
                }
            }
        }
        else
        {
            // Replace placeholder text
            if self.tokens.count == 0 && textView.text == ""
            {
                if let placeholderText = self.dataSource?.titleForTokenViewPlaceholder(self)
                {
                    textView.text = placeholderText
                    textView.textColor = UIColor.lightGray
                }
            }
        }
        
        self.delegate?.tokenViewDidEndEditing(self)
    }
    
    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        // Token Hidden TextView
        if textView.superview is NWSToken
        {
            if textView.text == "NWSTokenDeleteKey"
            {
                // Set text view to value of key press (ignore delete, space and return). Must be updated prior to calling delegate so the delegate is aware of any new text entered.
                if text != "" && text != " " && text != "\n"
                {
                    self.textView.text = text
                }
                
                // Delete Token
                self.delegate?.tokenView(self, didDeleteTokenAtIndex: textView.tag)
            }
            // Don't allow new characters to be entered or backspace wont delete token
            return false
        }
        else // Text View Input
        {
            // Blank return
            if textView.text == "" && text == "\n"
            {
                self.delegate?.tokenView(self, didEnterText: textView.text)
                return false
            }
            
            // Add new token
            if textView.text != "" && text == "\n"
            {
                self.shouldBecomeFirstResponder = true
                self.delegate?.tokenView(self, didEnterText: textView.text)
                return false
            }
            
            // Check if backspacing from empty text (to delete last token)
            if textView.text == "" && text == ""
            {
                if let token = self.tokens.last
                {
                    self.selectToken(token)
                }
                return false
            }
        }
        return true
    }
    
    open func textViewDidChange(_ textView: UITextView)
    {
        // Token Hidden TextView
        if textView.superview is NWSToken
        {
            // Do nothing for selected tokens
        }
        else // Text View Input
        {
            // Check if text view will overflow current line
            var scrollViewOriginY = textView.frame.origin.y
            let availableWidth = textView.bounds.width
            let maxWidth = self.scrollView.bounds.width - self.tokenViewInsets.left - self.tokenViewInsets.right
            
            let textWidth = self.tokenViewInsets.left + textView.attributedText.size().width + self.tokenViewInsets.right
            
            self.textView.frame.size = CGSize(width: self.textView.frame.size.width, height: self.textView.contentSize.height)
            
            // Check if text is greater than available width (on line with tokens/label), ignore if text view is already on it's own line
            if textWidth > availableWidth
            {
                var height = textView.frame.height
                
                // Only move text view to new line if it is not already on it's own line
                if textView.frame.origin.x != self.tokenViewInsets.left
                {
                    scrollViewOriginY += textView.bounds.height+self.tokenViewInsets.top
                }
                else
                {
                    // Grow height
                    self.textView.sizeToFit()
                    height = self.textView.frame.height
                }
                textView.frame = CGRect(x: self.tokenViewInsets.left, y: scrollViewOriginY, width: maxWidth, height: height)
                self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.width, height: textView.frame.origin.y+height+self.tokenViewInsets.bottom)
                self.layoutIfNeeded()
            }
            self.textView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
            self.delegate?.tokenView(self, didChangeText: textView.text)
        }
    }
    
    /// Dismiss keyboard and resign responder for Token View
    open func dismissTokenView()
    {
        self.resignFirstResponder()
        self.endEditing(true)
    }
    
    /// Scroll token view to bottom. Useful for scrolling along while user types in overflowing text or adds a new token.
    ///
    /// - parameter animated: Bool value for animating the scroll.
    fileprivate func scrollToBottom(animated: Bool)
    {
        let bottomPoint = CGPoint(x: 0, y: self.scrollView.contentSize.height-self.scrollView.bounds.height)
        self.scrollView.setContentOffset(bottomPoint, animated: animated)
    }
}


