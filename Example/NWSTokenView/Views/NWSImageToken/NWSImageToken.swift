//
//  NWSImageToken.swift
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
import NWSTokenView

public class NWSImageToken: NWSToken
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    public class func initWithTitle(title: String, image: UIImage? = nil) -> NWSImageToken?
    {
        if let token = UINib(nibName: "NWSImageToken", bundle:nil).instantiateWithOwner(nil, options: nil)[0] as? NWSImageToken
        {
            token.backgroundColor = UIColor(red: 98.0/255.0, green: 203.0/255.0, blue: 255.0/255.0, alpha: 1.0)
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
            
            return token
        }
        return nil
    }
}
