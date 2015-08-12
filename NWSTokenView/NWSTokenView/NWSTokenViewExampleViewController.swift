//
//  NWSTokenViewExampleViewController.swift
//  NWSTokenView
//
//  Created by James Hickman on 8/11/15.
//  Copyright (c) 2015 NitWit Studios. All rights reserved.
//

import UIKit

class NWSTokenViewExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NWSTokenDataSource, NWSTokenDelegate
{
    @IBOutlet weak var tokenView: NWSTokenView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tokenViewHeightConstraint: NSLayoutConstraint!
    
    let tokenViewMinHeight: CGFloat = 40.0
    let tokenViewMaxHeight: CGFloat = 120.0
    
    var contacts: [NWSTokenContact]!
    var selectedContacts = [NWSTokenContact]()
    var isSearching = false
    
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

    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("NWSTokenViewExampleCellIdentifier", forIndexPath: indexPath) as! NWSTokenViewExampleCell
        if let contact = contacts?[indexPath.row]
        {
            cell.userTitleLabel.text = contact.name
            cell.cellImageView.image = contact.image
        }
        return cell
    }
    
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
            self.selectedContacts.removeAtIndex(Int(index))
//            self.didUpdateParticipants()
            
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
//        if tokenView.textView.text.isEmail()
//        {
//            self.didTypeEmailInTokenView()
//        }
        
        self.isSearching = false
//        self.displayContactsForType(currentContactType)
    }
    
    func tokenView(tokenView: NWSTokenView, didChangeText text: String)
    {
        // Check if empty
        if text == ""
        {
            self.isSearching = false
            self.tableView.reloadData()
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
//            SuNotifications.showThinMessageNotification(loc("message.conversation.invalidemail.error"), inViewController: self, underView: recipientView, isSticky: false, tapNotificationHandler: {SuNotifications.hideNotification()})
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
    
    // MARK: Search Contacts
    func searchContacts(text: String)
    {
        // Reset filtered contacts
//        self.filteredParticipants = [:]
//        self.filteredParticipantSections = []
//        
//        // Use all participants
//        self.currentParticipants = self.sortedParticipants(self.allParticipants)
//        
//        // Hide preview
//        self.togglePreview(false, animated: true)
//        
//        // Hide tab view
//        self.toggleTabView(false, animated: true)
//        
//        // Hide tooltips
//        SuTooltipController.hideAllPresentedTooltips()
//        
//        // Filter contacts
//        if self.allParticipants.count > 0
//        {
//            for (key, var contacts) in self.currentParticipants
//            {
//                self.filteredParticipants[key] = contacts.filter({ (contact: SuConversationParticipant) -> Bool in
//                    if contact.suUser != nil
//                    {
//                        return (contact.suUser?.username.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil // Username
//                            || contact.suUser?.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil // Real Name
//                            || contact.suUser?.email.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil) // Email
//                    }
//                    if let apContact = contact.apContact
//                    {
//                        // Do a full search of all contact text
//                        var fullString = ""
//                        if let firstName = apContact.firstName
//                        {
//                            fullString += " " + firstName
//                        }
//                        if let lastName = apContact.lastName
//                        {
//                            fullString += " " + lastName
//                        }
//                        if let company = apContact.company
//                        {
//                            fullString += " " + company
//                        }
//                        if let email = apContact.emails[0] as? String
//                        {
//                            fullString += " " + email
//                        }
//                        return (fullString.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil)
//                    }
//                    return false
//                })
//                // Ignore empty results
//                if self.filteredParticipants[key]?.count == 0
//                {
//                    self.filteredParticipants.removeValueForKey(key)
//                }
//            }
//            // Sort Sections
//            let alphabetKeys = Array(self.filteredParticipants.keys)
//            self.filteredParticipantSections = alphabetKeys.sorted{ $0 < $1 }
//            
//            // Only load when starting  search
//            if !self.isSearching
//            {
//                self.togglePreview(false, animated: true)
//                self.displayContactsForType(.All)
//            }
//            
//            self.isSearching = true
//            self.tableView.reloadData()
//        }
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

    

}

class NWSTokenContact: NSObject
{
    var image: UIImage!
    var name: String!
    
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
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var userTitleLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        cellImageView.layer.cornerRadius = 5.0
        cellImageView.clipsToBounds = true
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

