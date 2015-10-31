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
    func insetsForTokenView(tokenView: NWSTokenView) -> UIEdgeInsets?
    func numberOfTokensForTokenView(tokenView: NWSTokenView) -> Int
    func titleForTokenViewLabel(tokenView: NWSTokenView) -> String?
    func titleForTokenViewPlaceholder(tokenView: NWSTokenView) -> String?
    func tokenView(tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView?
}

// MARK: NWSTokenDelegate Protocols
public protocol NWSTokenDelegate
{
    func tokenView(tokenView: NWSTokenView, didSelectTokenAtIndex index: Int)
    func tokenView(tokenView: NWSTokenView, didDeselectTokenAtIndex index: Int)
    func tokenView(tokenView: NWSTokenView, didDeleteTokenAtIndex index: Int)
    func tokenView(tokenViewDidBeginEditing: NWSTokenView)
    func tokenViewDidEndEditing(tokenView: NWSTokenView)
    func tokenView(tokenView: NWSTokenView, didChangeText text: String)
    func tokenView(tokenView: NWSTokenView, didEnterText text: String)
    func tokenView(tokenView: NWSTokenView, contentSizeChanged size: CGSize)
    func tokenView(tokenView: NWSTokenView, didFinishLoadingTokens tokenCount: Int)
}

// MARK: NWSTokenView Class
public class NWSTokenView: UIView, UIScrollViewDelegate, UITextViewDelegate
{
    @IBInspectable public var dataSource: NWSTokenDataSource? = nil
    @IBInspectable public var delegate: NWSTokenDelegate? = nil
    
    // MARK: Private Vars
    private var shouldBecomeFirstResponder: Bool = false
    private var scrollView = UIScrollView()
    public var textView = UITextView()
    private var lastTokenCount = 0
    private var lastText = ""
    
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
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib()
    {
        super.awakeFromNib()
        
        // Set default scroll properties
        self.scrollView.backgroundColor = UIColor.clearColor()
        self.scrollView.scrollEnabled = true
        self.scrollView.userInteractionEnabled = true
        self.scrollView.autoresizesSubviews = false
        self.addSubview(self.scrollView)
        
        // Set default label properties
        self.label.font = UIFont(name: "HelveticaNeue", size: 14)
        self.label.textColor = UIColor.blackColor()
        
        // Set default text view properties
        self.textView.backgroundColor = UIColor.clearColor()
        self.textView.textColor = UIColor.blackColor()
        self.textView.font = UIFont(name: "HelveticaNeue", size: 14)
        self.textView.delegate = self
        self.textView.scrollEnabled = false
        self.textView.autocorrectionType = UITextAutocorrectionType.No // Hide suggestions to prevent UI issues with message bar / keyboard.
        self.scrollView.addSubview(self.textView)
        
        // Auto Layout Constraints
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        let constraintLeft = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 0)
        let constraintRight = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0)
        let constraintTop = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0)
        let constraintBottom = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0)
        self.addConstraints([constraintLeft, constraintRight, constraintTop, constraintBottom])
        self.layoutIfNeeded()
        
        // Orientation Rotation Listener
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRotateInterfaceOrientation", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    /// Reloads data when interface orientation is changed.
    func didRotateInterfaceOrientation()
    {
        // Ignore "flat" orientation
        if UIDevice.currentDevice().orientation == UIDeviceOrientation.FaceUp || UIDevice.currentDevice().orientation == UIDeviceOrientation.FaceDown || UIDevice.currentDevice().orientation == UIDeviceOrientation.Unknown
        {
            return
        }
        
        // Prevent keyboard from hiding on rotation due to reloadData called from delegate
        if self.textView.isFirstResponder()
        {
            self.shouldBecomeFirstResponder = true
        }
        
        // Save rotation flag (for use with selected tokens)
        self.didReloadFromRotation = true
        
        self.reloadData()
    }
    
    /// Reloads data from datasource and delegate implementations.
    public func reloadData()
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
        for var index = 0; index < dataSource?.numberOfTokensForTokenView(self); index++
        {
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
            self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.width, scrollViewOriginY+max(textViewMinimumHeight, self.tokenHeight)+self.tokenViewInsets.top)
        }
        else
        {
            self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.width, scrollViewOriginY+textViewMinimumHeight+self.tokenViewInsets.top)
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
    private func resetTokenView()
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
    private func setupLabel(inout offsetX x: CGFloat, inout offsetY y: CGFloat, inout remainingWidth: CGFloat)
    {
        if let labelText = self.dataSource?.titleForTokenViewLabel(self)
        {
            self.label.bounds.size = CGSizeMake(self.labelMinimumWidth, self.labelMinimumHeight)
            self.label.text = labelText
            self.label.frame = CGRectMake(x, y, self.label.bounds.width-self.tokenViewInsets.left-self.tokenViewInsets.right, self.labelMinimumHeight)
            self.label.sizeToFit()
            // Reset frame after sizeToFit
            self.label.frame = CGRectMake(x, y, self.label.bounds.width, self.labelMinimumHeight)
            self.scrollView.addSubview(self.label)
            x += self.label.bounds.width
            remainingWidth -= x
        }
        
    }
    
    /// Sets up token view text view.
    private func setupTextView(inout offsetX x: CGFloat, inout offsetY y: CGFloat, inout remainingWidth: CGFloat)
    {
        // Set placeholder text (ignore if tokens exist, text exists, or is currently active field)
        if self.tokens.count == 0 && self.lastText == "" && !self.shouldBecomeFirstResponder
        {
            if let placeholderText = self.dataSource?.titleForTokenViewPlaceholder(self)
            {
                self.textView.text = placeholderText
                self.textView.textColor = UIColor.lightGrayColor()
            }
        }
        else
        {
            self.textView.textColor = UIColor.blackColor()
            self.textView.text = ""
        }
        
        // Get remaining width on line
        if remainingWidth >= self.textViewMinimumWidth
        {
            self.textView.frame = CGRectMake(x + self.tokenViewInsets.left, y, remainingWidth - self.tokenViewInsets.left - self.tokenViewInsets.right, max(self.textViewMinimumHeight, self.tokenHeight))
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
            
            self.textView.frame = CGRectMake(x + self.tokenViewInsets.left, y, remainingWidth - self.tokenViewInsets.left - self.tokenViewInsets.right, max(self.textViewMinimumHeight, self.tokenHeight))
        }
        
        self.textView.returnKeyType = UIReturnKeyType.Next
    }
    
    /// Sets up new token.
    private func setupToken(inout token: NWSToken, atIndex index: Int, inout withOffsetX x: CGFloat, inout withOffsetY y: CGFloat, inout remainingWidth: CGFloat)
    {
        // Add to token collection
        self.tokens.append(token)
        
        // Set hidden text view delegate for deselecting
        token.hiddenTextView.delegate = self
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action:"didTapToken:")
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
        token.frame = CGRectMake(x+self.tokenViewInsets.left, y, min(token.bounds.width, self.scrollView.bounds.width-x-self.tokenViewInsets.left-self.tokenViewInsets.right), token.bounds.height)
        
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
    public func tokenForIndex(index: Int) -> NWSToken
    {
        return self.tokens[index]
    }
    
    /// Selects the tapped token for interaction (i.e. removal).
    ///
    /// - parameter tapGesture: UITapGestureRecognizer associated with the token.
    ///
    /// - returns: NWSToken
    public func didTapToken(tapGesture: UITapGestureRecognizer)
    {
        let token = tapGesture.view as! NWSToken
        self.selectToken(token)
    }
    
    public func selectToken(token: NWSToken)
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
    public func textViewDidBeginEditing(textView: UITextView)
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
                    textView.textColor = UIColor.blackColor()
                }
            }
            
        }
        
        // Notify delegate
        self.delegate?.tokenView(self)
    }
    
    public func textViewDidEndEditing(textView: UITextView)
    {
        // Check if text view is input or hidden
        if textView.superview is NWSToken
        {
            // Force deselect if another responder is activated
            for (index, token) in self.tokens.enumerate()
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
                    textView.textColor = UIColor.lightGrayColor()
                }
            }
        }
        
        self.delegate?.tokenViewDidEndEditing(self)
    }
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
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
    
    public func textViewDidChange(textView: UITextView)
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
            
            self.textView.frame.size = CGSizeMake(self.textView.frame.size.width, self.textView.contentSize.height)
            
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
                textView.frame = CGRectMake(self.tokenViewInsets.left, scrollViewOriginY, maxWidth, height)
                self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.width, textView.frame.origin.y+height+self.tokenViewInsets.bottom)
                self.layoutIfNeeded()
            }
            self.textView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
            self.delegate?.tokenView(self, didChangeText: textView.text)
        }
    }
    
    /// Dismiss keyboard and resign responder for Token View
    public func dismissTokenView()
    {
        self.resignFirstResponder()
        self.endEditing(true)
    }
    
    /// Scroll token view to bottom. Useful for scrolling along while user types in overflowing text or adds a new token.
    ///
    /// - parameter animated: Bool value for animating the scroll.
    private func scrollToBottom(animated animated: Bool)
    {
        let bottomPoint = CGPointMake(0, self.scrollView.contentSize.height-self.scrollView.bounds.height)
        self.scrollView.setContentOffset(bottomPoint, animated: animated)
    }
}


