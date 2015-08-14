//
//  NWSToken.swift
//  NWSTokenView
//
//  Created by James Hickman on 8/11/15.
//  Copyright (c) 2015 NitWit Studios. All rights reserved.
//

import UIKit

class NWSToken: UIView
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    var hiddenTextView = UITextView()
    var isSelected: Bool = false
    
    
    class func initWithTitle(title: String, image: UIImage? = nil) -> NWSToken?
    {
        if var token = UINib(nibName: "NWSToken",bundle:nil).instantiateWithOwner(nil, options: nil)[0] as? NWSToken
        {
            let oldTextWidth = token.titleLabel.bounds.width
            token.titleLabel.text = title
            token.titleLabel.sizeToFit()
            token.titleLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            let newTextWidth = token.titleLabel.bounds.width
            
            token.imageView.image = image
            token.imageView.layer.cornerRadius = 5.0
            token.imageView.clipsToBounds = true
            token.layer.cornerRadius = 5.0
            token.clipsToBounds = true
            
            // Resize to fit text
            token.frame.size = CGSizeMake(token.frame.size.width+(newTextWidth-oldTextWidth), token.frame.height)
            token.setNeedsLayout()
            token.frame = token.frame
            
            // Hide text view (for using keyboard to delete token)
            token.hiddenTextView.hidden = true
            token.hiddenTextView.text = "NWSTokenDeleteKey" // Set default text for detection in delegate
            token.hiddenTextView.autocorrectionType = UITextAutocorrectionType.No // Hide suggestions to prevent key from being displayed
            token.addSubview(token.hiddenTextView)
            
            return token
        }
        
        return nil
    }

}
