//
//  ContactsTableViewController.swift
//  LazyCalendar
//
//  Created by Ying Tao on 7/22/15.
//  Copyright (c) 2015 Kim. All rights reserved.
//

import UIKit
import AddressBook
import AddressBookUI

// TODO: Put in editing mode. Right swipe = delete. Click below table = add. Select person = view details.
class ContactsTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    /*private let contactProperties = [kABPersonFirstNameProperty,
        kABPersonLastNameProperty,
        kABPersonMiddleNameProperty,
        kABPersonPrefixProperty,
        kABPersonSuffixProperty,
        kABPersonNicknameProperty,
        kABPersonFirstNamePhoneticProperty,
        kABPersonLastNamePhoneticProperty,
        kABPersonMiddleNamePhoneticProperty,
        
        kABPersonOrganizationProperty,
        kABPersonJobTitleProperty,
        kABPersonDepartmentProperty,
        kABPersonEmailProperty,
        
        kABPersonAddressProperty,
        kABPersonDateProperty,
        kABPersonKindProperty,
        
        kABPersonSocialProfileProperty,
        kABPersonURLProperty]*/
    
    private var addressBookRef: ABAddressBookRef!
    
    private var allContacts: NSArray!
    var selectedContacts = [ABRecordRef]()
    private var filteredContacts = [ABRecordRef]()
    
    private let reuseIdentifier = "ContactCell"
    
    private var searchController: UISearchController?
    
    
    /*
        @brief Set delegates and data sources, load address book, get contacts, and create the search controller.
        @discussion The segue to this controller is only initiated if
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set table view delegate and data source
        tableView.delegate = self
        tableView.dataSource = self
        
        // Address book must be authorized, otherwise throw exception.
        if ABAddressBookGetAuthorizationStatus() == .Authorized {
            addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        }
        else {
            var error: NSError?
            NSException.raise("AddressBookAccessNotAuthorizedException", format: "Error: %a", arguments: getVaList([error!]))
        }
        
        // Get all contacts
        allContacts = ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as NSArray
        
        // Create and configure search controller
        searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.delegate = self
            controller.delegate = self
            //controller.hidesNavigationBarDuringPresentation = false
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
    }
    
    
    /*
        @brief Filters the search results by the text entered in the search bar.
        @param searchText The text to filter the results.
    */
    func filterContentForSearchText(searchText: String) {
        let block = {
            (record: AnyObject!, bindings: [NSObject: AnyObject]!) -> Bool in
            let recordRef: ABRecordRef = record as ABRecordRef
            
            // Check if record is already recorded in selected contacts, don't show if already a selected contact.
            for (var i = 0; i < self.selectedContacts.count; i++) {
                if ABRecordGetRecordID(recordRef) == ABRecordGetRecordID(self.selectedContacts[i]) {
                    return false
                }
            }
            
            // Get name, phone numbers, and emails
            let name = ABRecordCopyCompositeName(recordRef)?.takeRetainedValue() as? String
            let phoneNumbersMultivalue: AnyObject? = ABRecordCopyValue(recordRef, kABPersonPhoneProperty)?.takeRetainedValue()
            let emailsMultivalue: AnyObject? = ABRecordCopyValue(recordRef, kABPersonEmailProperty)?.takeRetainedValue()
            
            // Search name for search text
            if name?.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil {
                return true
            }
            
            // Search phone numbers for search text
            for (var i = 0; i < ABMultiValueGetCount(phoneNumbersMultivalue!); i++) {
                let phoneNumber = ABMultiValueCopyValueAtIndex(phoneNumbersMultivalue!, i).takeRetainedValue() as! String
                if phoneNumber.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil {
                    return true
                }
            }
            
            // Search emails for search text
            for (var i = 0; i < ABMultiValueGetCount(emailsMultivalue); i++) {
                let email = ABMultiValueCopyValueAtIndex(emailsMultivalue, i).takeRetainedValue() as! String
                if email.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil {
                    return true
                }
            }
            
            /*for (var i = 0; i < self.contactProperties.count; i++) {
                let value = ABRecordCopyValue(record as ABRecordRef, self.contactProperties[i])
                if value != nil {
                    let retainedValue = value.takeRetainedValue()
                    println("PROPERTY: \(self.contactProperties[i])")
                    println(object_getClass(retainedValue).description())
                    
                    if (object_getClass(retainedValue).description() == "__NSCFType") {
                        let multivalue = retainedValue as ABMultiValueRef
                        for (var j = 0; j < ABMultiValueGetCount(multivalue); j++) {
                            let multivalueValue = ABMultiValueCopyValueAtIndex(multivalue, j)
                            
                            if multivalueValue != nil {
                                let retainedMultivalue = multivalueValue.takeRetainedValue()
                                println(retainedMultivalue)
                            }
                        }
                    }
                    else {
                        println(retainedValue)
                    }
                }
            }*/
            return false
        }
        // Create predicate and filter by predicate
        let predicate = NSPredicate(block: block)
        filteredContacts = allContacts.filteredArrayUsingPredicate(predicate) as [ABRecordRef]
        
        // Sort filtered contact IDs by alphabetical name
        filteredContacts.sort({
            let firstFullName = ABRecordCopyCompositeName($0).takeRetainedValue() as! String
            let secondFullName = ABRecordCopyCompositeName($1).takeRetainedValue() as! String

            return firstFullName.compare(secondFullName) == .OrderedAscending
        })
    }
    
    
    /*
        @brief Updates search results by filtering by the search bar text.
    */
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text)
        tableView.reloadData()
    }
    
    
    /*
        @brief There is one section in the contacts list.
    */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    /*
        @brief The number of rows is determined by the number of contacts.
        @discussion If the search controller is active, show the filtered contacts. If the search controller is inactive, show the selected contacts.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController != nil && searchController!.active {
            return filteredContacts.count
        }
        return selectedContacts.count
    }
    
    
    /*
        @brief If searching, selection will append to selected contacts and deactive the search controller.
        @discussion The filter ensures that search results will not show contacts that are already selected, so this method cannot add duplicate contacts.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchController != nil && searchController!.active {
            selectedContacts.append(filteredContacts[indexPath.row])
            
            searchController!.active = false
        }
        else {
            let personViewController = ABPersonViewController()
            personViewController.displayedPerson = selectedContacts[indexPath.row]
            navigationController?.showViewController(personViewController, sender: self)
        }
    }
    
    
    /*
        @brief Configures each cell in table view with contact information.
        @discussion The prototype cells are subtitle types so they have a main text label and detail text label. The main text label displays the contact's first and last name. The detail text label (for now) displays the contact's main phone number.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        // Show filtered records
        if searchController != nil && searchController!.active {
            let fullName = ABRecordCopyCompositeName(filteredContacts[indexPath.row])?.takeRetainedValue() as? String
            cell.textLabel?.text = fullName
        }
        // Show selected records
        else {
            let fullName = ABRecordCopyCompositeName(selectedContacts[indexPath.row])?.takeRetainedValue() as? String
            cell.textLabel?.text = fullName
        }

        return cell
    }
    
    
    /*
        @brief On view exit, updates the change event view controller contacts.
    */
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Keep only IDs of selected contacts
        var selectedContactIDs = [ABRecordID]()
        for contact in selectedContacts {
            selectedContactIDs.append(ABRecordGetRecordID(contact))
        }
        
        // Return selected contacts to change event view controller
        let changeEventViewController = self.navigationController?.viewControllers.first as? ChangeEventViewController
        changeEventViewController?.updateContacts(selectedContactIDs)
    }
}