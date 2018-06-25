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
@objc public protocol NWSTokenDataSource: class
{
    func numberOfTokensForTokenView(_ tokenView: NWSTokenView) -> Int
    func tokenView(_ tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView?
}

// MARK: NWSTokenDelegate Protocols
@objc public protocol NWSTokenDelegate: class
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
@IBDesignable
open class NWSTokenView: UIView, UIScrollViewDelegate, UITextViewDelegate
{
    @IBOutlet open weak var dataSource: NWSTokenDataSource? = nil
    @IBOutlet open weak var delegate: NWSTokenDelegate? = nil
    
    // MARK: Private Vars
    fileprivate var shouldBecomeFirstResponder: Bool = false
    fileprivate var scrollView = UIScrollView()
    fileprivate var textView = FixCaretTextView()
    fileprivate var lastTokenCount = 0

    // MARK: Inspectables
    @IBInspectable
    public var textColor: UIColor? {
        get {
            return textView.textColor
        }
        set {
            textView.textColor = newValue
        }
    }

    @IBInspectable
    public var titleColor: UIColor {
        get {
            return label.textColor
        }
        set {
            label.textColor = newValue
        }
    }

    @IBInspectable
    public var titleText: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }

    @IBInspectable
    public var placeholderColor: UIColor {
        get {
            return placeholder.textColor
        }
        set {
            placeholder.textColor = newValue
        }
    }

    @IBInspectable
    public var placeholderText: String? {
        get {
            return placeholder.text
        }
        set {
            placeholder.text = newValue
        }
    }

    // MARK: Wish could be IBInspectable...
    public var tokenViewInsets: UIEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5) // Default

    public var titleFont: UIFont {
        get {
            return label.font
        }
        set {
            label.font = newValue
        }
    }

    public var textFont: UIFont? {
        get {
            return textView.font
        }
        set {
            textView.font = newValue
            placeholder.font = newValue
        }
    }

    // MARK: Public Vars
    var label = UILabel()
    var placeholder = UILabel()
    var tokens: [NWSToken] = []
    var selectedToken: NWSToken?
    var tokenHeight: CGFloat = 30.0 // Default
    var didReloadFromRotation = false
    
    // MARK: Constants
    let labelMinimumHeight: CGFloat = 30.0
    let labelMinimumWidth: CGFloat = 30.0
    let textViewMinimumWidth: CGFloat = 30.0
    let textViewMinimumHeight: CGFloat = 30.0
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update scroll view content size
        let contentSize = self.scrollView.contentSize
        self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.width, height: contentSize.height)
    }

    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)

        // Set default scroll properties
        self.scrollView.backgroundColor = .clear
        self.scrollView.isScrollEnabled = true
        self.scrollView.isUserInteractionEnabled = true
        self.scrollView.autoresizesSubviews = false
        self.addSubview(self.scrollView)
        
        // Set default label properties
        self.label.font = UIFont.systemFont(ofSize: 16)
        self.label.textColor = UIColor.black
        self.scrollView.addSubview(self.label)

        // Set default text view properties
        self.textView.backgroundColor = UIColor.clear
        self.textView.textColor = UIColor.black
        self.textView.font = UIFont.systemFont(ofSize: 16)
        self.textView.delegate = self
        self.textView.isScrollEnabled = false
        self.textView.autocorrectionType = UITextAutocorrectionType.no // Hide suggestions to prevent UI issues with message bar / keyboard.
        self.scrollView.addSubview(self.textView)

        self.placeholder.backgroundColor = .clear
        self.placeholder.textColor = .lightGray
        self.placeholder.font = self.textView.font
        self.scrollView.addSubview(self.placeholder)
        
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

    @discardableResult override open func becomeFirstResponder() -> Bool
    {
        return self.textView.becomeFirstResponder()
    }

    override open var isFirstResponder: Bool
    {
        return self.textView.isFirstResponder
    }

    public var text: String
    {
        get
        {
            return textView.text
        }
        set
        {
            textView.text = newValue
            self.delegate?.tokenView(self, didChangeText: newValue)
        }
    }
    
    /// Reloads data when interface orientation is changed.
    @objc func didRotateInterfaceOrientation()
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
        
        // Set origins
        var scrollViewOriginX: CGFloat = self.tokenViewInsets.left
        var scrollViewOriginY: CGFloat = self.tokenViewInsets.top
        
        // Track remaining width
        var remainingWidth = self.scrollView.bounds.width
        
        // Add label
        self.setupLabel(offsetX: &scrollViewOriginX, offsetY: &scrollViewOriginY, remainingWidth:&remainingWidth)
        
        // Add Tokens
        let numOfTokens: Int = (dataSource?.numberOfTokensForTokenView(self)) ?? 0
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
    }
    
    /// Sets up token view label.
    fileprivate func setupLabel(offsetX x: inout CGFloat, offsetY y: inout CGFloat, remainingWidth: inout CGFloat)
    {
        if let labelText = self.label.text
        {
            self.label.bounds.size = CGSize(width: self.labelMinimumWidth, height: self.labelMinimumHeight)
            self.label.frame = CGRect(x: x, y: y, width: self.label.bounds.width-self.tokenViewInsets.left-self.tokenViewInsets.right, height: self.labelMinimumHeight)
            self.label.sizeToFit()
            // Reset frame after sizeToFit
            self.label.frame = CGRect(x: x, y: y, width: self.label.bounds.width, height: self.labelMinimumHeight)
            x += self.label.bounds.width
            remainingWidth -= x
        }
        
    }
    
    private var emptyTextViewFrame = CGRect.zero

    // TODO: Figure out a non-magic way of fixing vertical alignment.
    private let magicYOffset: CGFloat = 3

    /// Sets up token view text view.
    fileprivate func setupTextView(offsetX x: inout CGFloat, offsetY y: inout CGFloat, remainingWidth: inout CGFloat)
    {
        // Set placeholder text (ignore if tokens exist, text exists, or is currently active field)
        self.placeholder.isHidden = self.tokens.count > 0 || self.textView.text.count > 0

        // Get remaining width on line
        if remainingWidth >= self.textViewMinimumWidth
        {
            self.textView.frame = CGRect(x: x + self.tokenViewInsets.left, y: y - magicYOffset, width: remainingWidth - self.tokenViewInsets.left - self.tokenViewInsets.right, height: max(self.textViewMinimumHeight, self.tokenHeight))
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
            
            self.textView.frame = CGRect(x: x + self.tokenViewInsets.left, y: y - magicYOffset, width: remainingWidth - self.tokenViewInsets.left - self.tokenViewInsets.right, height: max(self.textViewMinimumHeight, self.tokenHeight))
        }
        self.emptyTextViewFrame = self.textView.frame

        let textContainerInset = self.textView.textContainerInset
        var placeHolderFrame = self.textView.frame
        placeHolderFrame.origin.x += self.textView.textContainer.lineFragmentPadding
        placeHolderFrame.origin.y += magicYOffset
        self.placeholder.frame = placeHolderFrame

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
    @objc open func didTapToken(_ tapGesture: UITapGestureRecognizer)
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
            let availableWidth = textView.bounds.width
            let textWidth = self.tokenViewInsets.left + textView.attributedText.size().width + self.tokenViewInsets.right
            
            var textViewOriginX = self.tokenViewInsets.left
            var scrollViewOriginY = textView.frame.origin.y
            var width = self.scrollView.bounds.width - self.tokenViewInsets.left - self.tokenViewInsets.right
            var height = textView.frame.height
            var heightChanged = false

            self.textView.frame.size.height = self.textView.contentSize.height
            // Check if size decreased and I can go back to the previous line
            if textWidth <= emptyTextViewFrame.size.width && textView.frame.origin.x != emptyTextViewFrame.origin.x {
                scrollViewOriginY = emptyTextViewFrame.origin.y
                textViewOriginX = emptyTextViewFrame.origin.x
                width = emptyTextViewFrame.size.width
                heightChanged = true
            }
            // Check if text is greater than available width (on line with tokens/label), ignore if text view is already on it's own line
            else if textWidth > availableWidth
            {
                // Only move text view to new line if it is not already on it's own line
                if textView.frame.origin.x != self.tokenViewInsets.left
                {
                    scrollViewOriginY += textView.bounds.height + self.tokenViewInsets.top
                }
                else
                {
                    // Grow height
                    self.textView.sizeToFit()
                    height = self.textView.frame.height
                }
                heightChanged = true
            }

            if heightChanged {
                textView.frame = CGRect(x: textViewOriginX, y: scrollViewOriginY, width: width, height: height)
                self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.width, height: textView.frame.origin.y + height+self.tokenViewInsets.bottom)
                self.layoutIfNeeded()

                // Notify delegate of content size change
                self.delegate?.tokenView(self, contentSizeChanged: self.scrollView.contentSize)
            }
            self.textView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
            self.delegate?.tokenView(self, didChangeText: textView.text)
            self.placeholder.isHidden = self.tokens.count > 0 || self.textView.text.count > 0
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

/// Used to fix a weird issue with the caret being taller when there's no text.
private class FixCaretTextView: UITextView {
    override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        if let h = self.font?.lineHeight {
            rect.size.height = h
        }
        return rect
    }
}
