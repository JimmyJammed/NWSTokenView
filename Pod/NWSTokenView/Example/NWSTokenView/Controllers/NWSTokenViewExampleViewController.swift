//
//  NWSTokenViewExampleViewController.swift
//  NWSTokenView
//
//  Created by James Hickman on 8/11/15.
//  Copyright (c) 2015 NitWit Studios. All rights reserved.
//

import UIKit
import NWSTokenView

class NWSTokenViewExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NWSTokenDataSource, NWSTokenDelegate, UIGestureRecognizerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate
{
    @IBOutlet weak var tokenView: NWSTokenView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tokenViewHeightConstraint: NSLayoutConstraint!
    
    let tokenViewMinHeight: CGFloat = 40.0
    let tokenViewMaxHeight: CGFloat = 120.0
    
    var isSearching = false
    var contacts: [NWSTokenContact]!
    var selectedContacts = [NWSTokenContact]()
    var filteredContacts = [NWSTokenContact]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create list of contacts to test
        let unsortedContacts = [NWSTokenContact(name: "Albus Dumbledore", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Rubeus Hagrid", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Harry Potter", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Hermione Granger", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Ron Weasley", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Minerva McGonagall", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Seamus Finnigan", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Draco Malfoy", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Severus Snape", andImage: UIImage(named: "TokenPlaceholder")!),
        NWSTokenContact(name: "Voldemort", andImage: UIImage(named: "TokenPlaceholder")!)]
        
        contacts = NWSTokenContact.sortedContacts(unsortedContacts)
        tokenView.dataSource = self
        tokenView.delegate = self
        tokenView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool
    {
        if touch.view.isDescendantOfView(tableView)
        {
            return false
        }
        return true
    }
    
    // MARK: Keyboard
    @IBAction func didTapView(sender: UITapGestureRecognizer)
    {
        dismissKeyboard()
    }
    
    func dismissKeyboard()
    {
        tokenView.resignFirstResponder()
        tokenView.endEditing(true)
    }
    
    // MARK: Search Contacts
    func searchContacts(text: String)
    {
        // Reset filtered contacts
        filteredContacts = []
        
        // Filter contacts
        if contacts.count > 0
        {
            filteredContacts = contacts.filter({ (contact: NWSTokenContact) -> Bool in
                return contact.name.rangeOfString(text, options: .CaseInsensitiveSearch) != nil
            })
            
            self.isSearching = true
            self.tableView.reloadData()
        }
    }
    
    func didTypeEmailInTokenView()
    {
        let email = self.tokenView.textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var contact = NWSTokenContact(name: email, andImage: UIImage(named: "TokenPlaceholder")!)
        self.selectedContacts.append(contact)
        
        self.tokenView.textView.text = ""
        self.isSearching = false
        self.tokenView.reloadData()
        self.tableView.reloadData()
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if isSearching
        {
            return filteredContacts.count
        }
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("NWSTokenViewExampleCellIdentifier", forIndexPath: indexPath) as! NWSTokenViewExampleCell
        
        let currentContacts: [NWSTokenContact]!
        
        // Check if searching
        if isSearching
        {
            currentContacts = filteredContacts
        }
        else
        {
            currentContacts = contacts
        }
        
        // Load contact data
        let contact = currentContacts[indexPath.row]
        cell.loadWithContact(contact)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var cell = tableView.cellForRowAtIndexPath(indexPath) as! NWSTokenViewExampleCell
        cell.selected = false
        
        // Check if already selected
        if !contains(selectedContacts, cell.contact)
        {
            cell.contact.isSelected = true
            selectedContacts.append(cell.contact)
            isSearching = false
            tokenView.textView.text = ""
            tokenView.reloadData()
            tableView.reloadData()
        }
    }
    
    // MARK: DZNEmptyDataSetSource
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage!
    {
        return UIImage(named: "Friends")!
    }

    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString!
    {
        let attributedString = NSAttributedString(string: "No Contacts Match", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        return attributedString
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor!
    {
        return UIColor.lightGrayColor()
    }
    
    // MARK: DZNEmptyDataSetDelegate
    
    
    // MARK: NWSTokenDataSource
    func numberOfTokensForTokenView(tokenView: NWSTokenView) -> Int {
        return selectedContacts.count
    }
    
    func insetsForTokenView(tokenView: NWSTokenView) -> UIEdgeInsets? {
        return UIEdgeInsetsMake(5, 5, 5, 5)
    }
    
    func titleForTokenViewLabel(tokenView: NWSTokenView) -> String?
    {
        return "To:"
    }
    
    func titleForTokenViewPlaceholder(tokenView: NWSTokenView) -> String?
    {
        return "Search contacts..."
    }
    
    func tokenView(tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView?
    {
        let contact = selectedContacts[Int(index)]
        if let token = NWSToken.initWithTitle(contact.name, image: contact.image)
        {
            return token
        }
        
        return nil
    }
    
    // MARK: NWSTokenDelegate
    func tokenView(tokenView: NWSTokenView, didSelectTokenAtIndex index: Int)
    {
        var token = tokenView.tokenForIndex(index)
        token.backgroundColor = UIColor.blueColor()
    }
    
    func tokenView(tokenView: NWSTokenView, didDeselectTokenAtIndex index: Int)
    {
        var token = tokenView.tokenForIndex(index)
        token.backgroundColor = UIColor.blueColor()
    }
    
    func tokenView(tokenView: NWSTokenView, didDeleteTokenAtIndex index: Int)
    {
        // Ensure index is within bounds
        if index < self.selectedContacts.count
        {
            var contact = self.selectedContacts[Int(index)] as NWSTokenContact
            contact.isSelected = false
            self.selectedContacts.removeAtIndex(Int(index))
            
            tokenView.reloadData()
            tableView.reloadData()
            tokenView.layoutIfNeeded()
            tokenView.textView.becomeFirstResponder()
            
            // Check if search text exists, if so, reload table (i.e. user deleted a selected token by pressing an alphanumeric key)
            if tokenView.textView.text != ""
            {
                //self.searchContacts(tokenView.textView.text)
            }
        }
    }
    
    func tokenView(tokenViewDidBeginEditing: NWSTokenView)
    {
        // Check if entering search field and it already contains text (ignore token selections)
        if tokenView.textView.isFirstResponder() && tokenView.textView.text != ""
        {
            //self.searchContacts(tokenView.textView.text)
        }
    }
    
    func tokenViewDidEndEditing(tokenView: NWSTokenView)
    {
        if tokenView.textView.text.isEmail()
        {
            didTypeEmailInTokenView()
        }
        
        isSearching = false
        tableView.reloadData()
    }
    
    func tokenView(tokenView: NWSTokenView, didChangeText text: String)
    {
        // Check if empty (deleting text)
        if text == ""
        {
            isSearching = false
            tableView.reloadData()
            return
        }
        
        // Check if typed an email and hit space
        var lastChar = text[text.endIndex.predecessor()]
        if lastChar == " " && text.substringWithRange(Range<String.Index>(start: text.startIndex, end: text.endIndex.predecessor())).isEmail()
        {
            self.didTypeEmailInTokenView()
            return
        }
        
        self.searchContacts(text)
    }
    
    func tokenView(tokenView: NWSTokenView, didEnterText text: String)
    {
        if text == ""
        {
            return
        }
        
        if text.isEmail()
        {
            self.didTypeEmailInTokenView()
        }
        else
        {

        }
    }
    
    func tokenView(tokenView: NWSTokenView, contentSizeChanged size: CGSize)
    {
        self.tokenViewHeightConstraint.constant = max(tokenViewMinHeight,min(size.height, self.tokenViewMaxHeight))
        self.view.layoutIfNeeded()
    }
    
    func tokenView(tokenView: NWSTokenView, didFinishLoadingTokens tokenCount: Int)
    {

    }

}

class NWSTokenContact: NSObject
{
    var image: UIImage!
    var name: String!
    var isSelected = false
    
    init(name: String, andImage image: UIImage)
    {
        self.name = name
        self.image = image
    }
    
    class func sortedContacts(contacts: [NWSTokenContact]) -> [NWSTokenContact]
    {
        return contacts.sorted({ (first, second) -> Bool in
            return first.name < second.name
        })
    }
}

class NWSTokenViewExampleCell: UITableViewCell
{
    @IBOutlet weak var userTitleLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var checkmarkImageView: UIImageView!
   
    var contact: NWSTokenContact!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        // Round corners
        userImageView.layer.cornerRadius = 5.0
        userImageView.clipsToBounds = true
        
        // Issue with storyboard tintColor not always setting properly, set in code.
        let image = UIImage(named: "Checkmark")?.imageWithRenderingMode(.AlwaysTemplate)
        checkmarkImageView.tintColor = UIColor(red: 61/255, green: 127/255, blue: 221/255, alpha: 1.0)
        checkmarkImageView.image = image
    }
    
    func loadWithContact(contact: NWSTokenContact)
    {
        self.contact = contact
        userTitleLabel.text = contact.name
        userImageView.image = contact.image
        
        // Show/Hide Checkmark
        if contact.isSelected
        {
            checkmarkImageView.hidden = false
        }
        else
        {
            checkmarkImageView.hidden = true
        }
    }
}

extension String
{
    func isEmail() -> Bool
    {
        let regex = NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive, error: nil)
        return regex?.firstMatchInString(self, options: nil, range: NSMakeRange(0, count(self))) != nil
    }
}

