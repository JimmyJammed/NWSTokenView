//
//  NWSTokenViewExampleViewController.swift
//  NWSTokenView
//
//  Created by James Hickman on 8/11/15.
//  Copyright (c) 2015 NitWit Studios. All rights reserved.
//

import UIKit
import NWSTokenView
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class NWSTokenViewExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NWSTokenDataSource, NWSTokenDelegate, UIGestureRecognizerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate
{
    @IBOutlet weak var tokenView: NWSTokenView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tokenViewHeightConstraint: NSLayoutConstraint!
    
    let tokenViewMinHeight: CGFloat = 40.0
    let tokenViewMaxHeight: CGFloat = 150.0
    let tokenBackgroundColor = UIColor(red: 98.0/255.0, green: 203.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    var isSearching = false
    var contacts: [NWSTokenContact]!
    var selectedContacts = [NWSTokenContact]()
    var filteredContacts = [NWSTokenContact]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Adjust tableView offset for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(NWSTokenViewExampleViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NWSTokenViewExampleViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Create list of contacts to test
        let unsortedContacts = [
            NWSTokenContact(name: "Albus Dumbledore", andImage: UIImage(named: "Albus-Dumbledore")!),
            NWSTokenContact(name: "Cedric Diggory", andImage: UIImage(named: "Cedric-Diggory")!),
            NWSTokenContact(name: "Cho Chang", andImage: UIImage(named: "Cho-Chang")!),
            NWSTokenContact(name: "Draco Malfoy", andImage: UIImage(named: "Draco-Malfoy")!),
            NWSTokenContact(name: "Fred Weasley", andImage: UIImage(named: "Fred-Weasley")!),
            NWSTokenContact(name: "George Weasley", andImage: UIImage(named: "George-Weasley")!),
            NWSTokenContact(name: "Ginny Weasley", andImage: UIImage(named: "Ginny-Weasley")!),
            NWSTokenContact(name: "Gregory Goyle", andImage: UIImage(named: "Gregory-Goyle")!),
            NWSTokenContact(name: "Harry Potter", andImage: UIImage(named: "Harry-Potter")!),
            NWSTokenContact(name: "Hermione Granger", andImage: UIImage(named: "Hermione-Granger")!),
            NWSTokenContact(name: "James Potter", andImage: UIImage(named: "James-Potter")!),
            NWSTokenContact(name: "Lily Potter", andImage: UIImage(named: "Lily-Potter")!),
            NWSTokenContact(name: "Luna Lovegood", andImage: UIImage(named: "Luna-Lovegood")!),
            NWSTokenContact(name: "Minerva McGonagal", andImage: UIImage(named: "Minerva-McGonagal")!),
            NWSTokenContact(name: "Moaning Myrtle", andImage: UIImage(named: "Moaning-Myrtle")!),
            NWSTokenContact(name: "Neville Longbottom", andImage: UIImage(named: "Neville-Longbottom")!),
            NWSTokenContact(name: "Nymphadora Tonks", andImage: UIImage(named: "Nymphadora-Tonks")!),
            NWSTokenContact(name: "Peter Pettigrew", andImage: UIImage(named: "Peter-Pettigrew")!),
            NWSTokenContact(name: "Remus Lupin", andImage: UIImage(named: "Remus-Lupin")!),
            NWSTokenContact(name: "Ron Weasley", andImage: UIImage(named: "Ron-Weasley")!),
            NWSTokenContact(name: "Rubeus Hagrid", andImage: UIImage(named: "Rubeus-Hagrid")!),
            NWSTokenContact(name: "Severus Snape", andImage: UIImage(named: "Severus-Snape")!),
            NWSTokenContact(name: "Sirius Black", andImage: UIImage(named: "Sirius-Black")!),
            NWSTokenContact(name: "Vincent Crabbe", andImage: UIImage(named: "Vincent-Crabbe")!),
            NWSTokenContact(name: "Voldemort", andImage: UIImage(named: "Voldemort")!),
        ]
        
        contacts = NWSTokenContact.sortedContacts(unsortedContacts)
        
        // TableView
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorStyle = .singleLine
        
        // TokenView
        tokenView.layoutIfNeeded()
        tokenView.dataSource = self
        tokenView.delegate = self
        tokenView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        if let view = touch.view
        {
            if view.isDescendant(of: tableView)
            {
                return false
            }
        }
        return true
    }
    
    // MARK: Keyboard
    func keyboardWillShow(_ notification: Notification)
    {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            tableView.contentInset = contentInsets
            tableView.scrollIndicatorInsets = contentInsets

        }        
    }
    
    func keyboardWillHide(_ notification: NotificationCenter)
    {
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    @IBAction func didTapView(_ sender: UITapGestureRecognizer)
    {
        dismissKeyboard()
    }
    
    func dismissKeyboard()
    {
        tokenView.resignFirstResponder()
        tokenView.endEditing(true)
    }
    
    // MARK: Search Contacts
    func searchContacts(_ text: String)
    {
        // Reset filtered contacts
        filteredContacts = []
        
        // Filter contacts
        if contacts.count > 0
        {
            filteredContacts = contacts.filter({ (contact: NWSTokenContact) -> Bool in
                return contact.name.range(of: text, options: .caseInsensitive) != nil
            })
            
            self.isSearching = true
            self.tableView.reloadData()
        }
    }
    
    func didTypeEmailInTokenView()
    {
        let email = self.tokenView.textView.text.trimmingCharacters(in: CharacterSet.whitespaces)
        let contact = NWSTokenContact(name: email, andImage: UIImage(named: "TokenPlaceholder")!)
        self.selectedContacts.append(contact)
        
        self.tokenView.textView.text = ""
        self.isSearching = false
        self.tokenView.reloadData()
        self.tableView.reloadData()
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if isSearching
        {
            return filteredContacts.count
        }
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NWSTokenViewExampleCellIdentifier", for: indexPath) as! NWSTokenViewExampleCell
        
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
        let contact = currentContacts[(indexPath as NSIndexPath).row]
        cell.loadWithContact(contact)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let cell = tableView.cellForRow(at: indexPath) as! NWSTokenViewExampleCell
        cell.isSelected = false
        
        // Check if already selected
        if !selectedContacts.contains(cell.contact)
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
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        
        if let view = UINib(nibName: "EmptyDataSet", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UIView
        {
            view.frame = scrollView.bounds
            view.translatesAutoresizingMaskIntoConstraints = false
            view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
            return view
        }

        return nil
    }
    
    
    // MARK: NWSTokenDataSource
    func numberOfTokensForTokenView(_ tokenView: NWSTokenView) -> Int
    {
        return selectedContacts.count
    }
    
    func insetsForTokenView(_ tokenView: NWSTokenView) -> UIEdgeInsets?
    {
        return UIEdgeInsetsMake(5, 5, 5, 5)
    }
    
    func titleForTokenViewLabel(_ tokenView: NWSTokenView) -> String?
    {
        return "To:"
    }
    
    func titleForTokenViewPlaceholder(_ tokenView: NWSTokenView) -> String?
    {
        return "Search contacts..."
    }
    
    func tokenView(_ tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView?
    {
        let contact = selectedContacts[Int(index)]
        if let token = NWSImageToken.initWithTitle(contact.name, image: contact.image)
        {
            return token
        }
        
        return nil
    }
    
    // MARK: NWSTokenDelegate
    func tokenView(_ tokenView: NWSTokenView, didSelectTokenAtIndex index: Int)
    {
        let token = tokenView.tokenForIndex(index) as! NWSImageToken
        token.backgroundColor = UIColor.blue
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeselectTokenAtIndex index: Int)
    {
        let token = tokenView.tokenForIndex(index) as! NWSImageToken
        token.backgroundColor = tokenBackgroundColor
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeleteTokenAtIndex index: Int)
    {
        // Ensure index is within bounds
        if index < self.selectedContacts.count
        {
            let contact = self.selectedContacts[Int(index)] as NWSTokenContact
            contact.isSelected = false
            self.selectedContacts.remove(at: Int(index))
            
            tokenView.reloadData()
            tableView.reloadData()
            tokenView.layoutIfNeeded()
            tokenView.textView.becomeFirstResponder()
            
            // Check if search text exists, if so, reload table (i.e. user deleted a selected token by pressing an alphanumeric key)
            if tokenView.textView.text != ""
            {
                self.searchContacts(tokenView.textView.text)
            }
        }
    }
    
    func tokenView(_ tokenViewDidBeginEditing: NWSTokenView)
    {
        // Check if entering search field and it already contains text (ignore token selections)
        if tokenView.textView.isFirstResponder && tokenView.textView.text != ""
        {
            //self.searchContacts(tokenView.textView.text)
        }
    }
    
    func tokenViewDidEndEditing(_ tokenView: NWSTokenView)
    {
        if tokenView.textView.text.isEmail()
        {
            didTypeEmailInTokenView()
        }
        
        isSearching = false
        tableView.reloadData()
    }
    
    func tokenView(_ tokenView: NWSTokenView, didChangeText text: String)
    {
        // Check if empty (deleting text)
        if text == ""
        {
            isSearching = false
            tableView.reloadData()
            return
        }
        
        // Check if typed an email and hit space
        let lastChar = text[text.characters.index(before: text.endIndex)]
        if lastChar == " " && text.substring(with: text.startIndex..<text.characters.index(before: text.endIndex)).isEmail()
        {
            self.didTypeEmailInTokenView()
            return
        }
        
        self.searchContacts(text)
    }
    
    func tokenView(_ tokenView: NWSTokenView, didEnterText text: String)
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
    
    func tokenView(_ tokenView: NWSTokenView, contentSizeChanged size: CGSize)
    {
        self.tokenViewHeightConstraint.constant = max(tokenViewMinHeight,min(size.height, self.tokenViewMaxHeight))
        self.view.layoutIfNeeded()
    }
    
    func tokenView(_ tokenView: NWSTokenView, didFinishLoadingTokens tokenCount: Int)
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
    
    class func sortedContacts(_ contacts: [NWSTokenContact]) -> [NWSTokenContact]
    {
        return contacts.sorted(by: { (first, second) -> Bool in
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
        
        checkmarkImageView.image = UIImage(named: "Bolt")
    }
    
    func loadWithContact(_ contact: NWSTokenContact)
    {
        self.contact = contact
        userTitleLabel.text = contact.name
        userImageView.image = contact.image
        
        // Show/Hide Checkmark
        if contact.isSelected
        {
            checkmarkImageView.isHidden = false
        }
        else
        {
            checkmarkImageView.isHidden = true
        }
    }
}

extension String
{
    func isEmail() -> Bool
    {
        let regex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .caseInsensitive)
        return regex?.firstMatch(in: self, options: [], range: NSMakeRange(0, self.characters.count)) != nil
    }
}

