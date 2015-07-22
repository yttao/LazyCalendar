//
//  ChangeEventViewController.swift
//  LazyCalendar
//
//  Created by Ying Tao on 7/9/15.
//  Copyright (c) 2015 Kim. All rights reserved.
//

import UIKit
import CoreData
import AddressBook
import AddressBookUI

class ChangeEventViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: ChangeEventViewControllerDelegate?
    
    // Date used for initialization info
    private var name: String?
    private var dateStart: NSDate?
    private var dateEnd: NSDate?
    private var alarm: Bool?
    private var alarmTime: NSDate?
    
    // Date formatter to control date appearances
    private let dateFormatter = NSDateFormatter()
    
    // Date start and end pickers to decide time interval
    private let dateStartPicker = UIDatePicker()
    private let dateEndPicker = UIDatePicker()

    // Text field for event name
    @IBOutlet weak var nameTextField: UITextField!
    
    // Labels to display event start info
    @IBOutlet weak var dateStartMainLabel: UILabel!
    @IBOutlet weak var dateStartDetailsLabel: UILabel!
    
    // Labels to display event end info
    @IBOutlet weak var dateEndMainLabel: UILabel!
    @IBOutlet weak var dateEndDetailsLabel: UILabel!
    
    // Toggles alarm option on/off
    @IBOutlet weak var alarmSwitch: UISwitch!
    @IBOutlet weak var alarmDateSwitch: UISwitch!
    
    // Displays alarm time
    @IBOutlet weak var alarmTimeMainLabel: UILabel!
    @IBOutlet weak var alarmTimeDetailsLabel: UILabel!
    
    // Picks alarm time
    @IBOutlet weak var alarmTimePicker: UIDatePicker!
    
    @IBOutlet weak var alarmDateToggleCell: UITableViewCell!
    @IBOutlet weak var alarmTimeDisplayCell: UITableViewCell!
    @IBOutlet weak var alarmTimePickerCell: UITableViewCell!
    
    // Section headers associated with section numbers
    private let sections = ["Name": 0, "Start": 1, "End": 2, "Alarm": 3, "Contacts": 4]
    
    // Keeps track of index paths
    private let indexPaths = ["Name": NSIndexPath(forRow: 0, inSection: 0),
        "Start": NSIndexPath(forRow: 0, inSection: 1), "End": NSIndexPath(forRow: 0, inSection: 2),
        "AlarmToggle": NSIndexPath(forRow: 0, inSection: 3),
        "AlarmDateToggle": NSIndexPath(forRow: 1, inSection: 3),
        "AlarmTimeDisplay": NSIndexPath(forRow: 2, inSection: 3),
        "AlarmTimePicker": NSIndexPath(forRow: 3, inSection: 3),
        "Contacts": NSIndexPath(forRow: 0, inSection: 4)]
    
    // Heights of fields
    private let DEFAULT_CELL_HEIGHT = UITableViewCell().frame.height
    private let PICKER_CELL_HEIGHT = UIPickerView().frame.height
    
    private var eventNameCellHeight: CGFloat
    
    private var eventDateStartCellHeight: CGFloat
    private var eventDateEndCellHeight: CGFloat
    
    private var alarmToggleCellHeight: CGFloat
    private var alarmDateToggleCellHeight: CGFloat
    private var alarmTimeDisplayCellHeight: CGFloat
    private var alarmTimePickerCellHeight: CGFloat
    
    private var selectedIndexPath: NSIndexPath?
    
    private var event: NSManagedObject?
    
    
    // Initialization, set default heights
    required init(coder aDecoder: NSCoder) {
        eventNameCellHeight = DEFAULT_CELL_HEIGHT
        
        eventDateStartCellHeight = DEFAULT_CELL_HEIGHT
        eventDateEndCellHeight = DEFAULT_CELL_HEIGHT
        
        alarmToggleCellHeight = DEFAULT_CELL_HEIGHT
        alarmDateToggleCellHeight = 0
        alarmTimeDisplayCellHeight = 0
        alarmTimePickerCellHeight = 0
        
        super.init(coder: aDecoder)
    }
    
    
    /*
        @brief Initialize information on view load.
        @discussion Provides setup information for the initial data, before the user changes anything.
        1. Set the table view delegate and data source if they are not already set.
        2. Disable the event name text field. This is done to allow proper cell selection (which is not possible if the text field can be clicked on within its section).
        3. Set date start picker date to the selected date (or the first day of the month if none are selected) and the picker time to the current time (in hours and minutes). Set date end picker time to show one hour after the date start picker date and time.
        4. Add event listeners that are informed when event date start picker or end picker are changed. Update the event start and end labels. Additionally, if the event start time is changed, the minimum time for the event end time is modified if the end time will come before the start time.
        5. Format the event start and end labels. The main labels show the format: month day, year. The details labels show the format: hour:minutes period.
        6. Default set the alarm switches off and the alarm time picker to the initial date start.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set tableview delegate and data source
        tableView.delegate = self
        tableView.dataSource = self
        
        // Disable text field user interaction, needed to allow proper table view row selection
        nameTextField.userInteractionEnabled = false
        
        // Add listener for when date start and end pickers update
        dateStartPicker.addTarget(self, action: "updateDateStart", forControlEvents: .ValueChanged)
        dateEndPicker.addTarget(self, action: "updateDateEnd", forControlEvents: .ValueChanged)
        
        // If using a pre-existing event, load data from event.
        if (event != nil) {
            nameTextField.text = name
            dateStartPicker.date = dateStart!
            dateEndPicker.date = dateEnd!
            dateEndPicker.minimumDate = dateStart!
            alarmSwitch.on = alarm!
            alarmDateSwitch.on = false
            if alarmTime != nil {
                alarmTimePicker.date = alarmTime!
                showMoreAlarmOptions()
            }
            else {
                alarmTimePicker.date = dateStart!
            }
            
            // Format and set main date labels
            dateFormatter.dateFormat = "MMM dd, yyyy"
            dateStartMainLabel.text = dateFormatter.stringFromDate(dateStart!)
            dateEndMainLabel.text = dateFormatter.stringFromDate(dateEnd!)
            if alarmTime != nil {
                alarmTimeMainLabel.text = dateFormatter.stringFromDate(alarmTime!)
            }
            else {
                alarmTimeMainLabel.text = dateFormatter.stringFromDate(dateStart!)
            }
            
            // Format and set details labels
            dateFormatter.dateFormat = "h:mm a"
            dateStartDetailsLabel.text = dateFormatter.stringFromDate(dateStart!)
            dateEndDetailsLabel.text = dateFormatter.stringFromDate(dateEnd!)
            if alarmTime != nil {
                alarmTimeDetailsLabel.text = dateFormatter.stringFromDate(alarmTime!)
            }
            else {
                alarmTimeDetailsLabel.text = dateFormatter.stringFromDate(dateStart!)
            }
        }
        // If creating a new event, load initial data.
        else {
            // Set initial picker value to selected date and end picker value to 1 hour later
            dateStartPicker.date = dateStart!
            dateEndPicker.date = dateEnd!
            dateEndPicker.minimumDate = dateStart!
            
            // Format and set main date labels
            dateFormatter.dateFormat = "MMM dd, yyyy"
            dateStartMainLabel.text = dateFormatter.stringFromDate(dateStart!)
            dateEndMainLabel.text = dateFormatter.stringFromDate(dateEnd!)
            alarmTimeMainLabel.text = dateFormatter.stringFromDate(dateStart!)
            
            // Format and set details labels
            dateFormatter.dateFormat = "h:mm a"
            dateStartDetailsLabel.text = dateFormatter.stringFromDate(dateStart!)
            dateEndDetailsLabel.text = dateFormatter.stringFromDate(dateEnd!)
            alarmTimeDetailsLabel.text = dateFormatter.stringFromDate(dateStart!)
            
            alarmSwitch.on = alarm!
            alarmDateSwitch.on = false
            
            alarmTimePicker.date = alarmTime!
        }
    }
    
    
    /*
        @brief Initializes data with a start date.
    */
    func loadData(#dateStart: NSDate) {
        name = nil
        self.dateStart = dateStart
        let hour = NSTimeInterval(3600)
        dateEnd = dateStart.dateByAddingTimeInterval(hour)
        alarm = false
        alarmTime = dateStart
    }
    
    
    /*
        @brief Initializes data with a pre-existing event.
    */
    func loadData(#event: NSManagedObject) {
        self.event = event
        name = event.valueForKey("name") as? String
        dateStart = event.valueForKey("dateStart") as? NSDate
        dateEnd = event.valueForKey("dateEnd") as? NSDate
        alarm = event.valueForKey("alarm") as? Bool
        alarmTime = event.valueForKey("alarmTime") as? NSDate
    }
    
    
    /*
        @brief Update date start info.
    */
    func updateDateStart() {
        dateStart = dateStartPicker.date
        updateDateStartLabels(dateStart!)
        updateDateEndPicker(dateStart!)
        updateAlarmTimePicker(dateStart!)
    }
    
    
    /*
        @brief Update date start labels.
    */
    func updateDateStartLabels(date: NSDate) {
        dateFormatter.dateFormat = "MMM dd, yyyy"
        dateStartMainLabel.text = dateFormatter.stringFromDate(dateStartPicker.date)
        
        dateFormatter.dateFormat = "h:mm a"
        dateStartDetailsLabel.text = dateFormatter.stringFromDate(dateStartPicker.date)
    }
    
    
    /*
        @brief Update date end info.
    */
    func updateDateEnd() {
        dateEnd = dateEndPicker.date
        updateDateEndLabels(dateEnd!)
    }
    
    
    /*
        @brief Update date end labels.
    */
    func updateDateEndLabels(date: NSDate) {
        dateFormatter.dateFormat = "MMM dd, yyyy"
        dateEndMainLabel.text = dateFormatter.stringFromDate(date)
        
        dateFormatter.dateFormat = "h:mm a"
        dateEndDetailsLabel.text = dateFormatter.stringFromDate(date)
    }
    
    
    /*
        @brief When date start picker is changed, update the minimum date.
        @discussion The date end picker should not be able to choose a date before the date start, so it should have a lower limit placed on the date it can choose.
    */
    func updateDateEndPicker(date: NSDate) {
        let originalDate = dateEndPicker.date
        dateEndPicker.minimumDate = date

        // If the old date end comes after the new date start, change the old date end to equal the new date start.
        if (originalDate.compare(dateStartPicker.date) == .OrderedAscending) {
            dateEndPicker.date = dateStartPicker.date
            updateDateEnd()
        }
        dateEndPicker.reloadInputViews()
    }
    
    
    /*
        @brief Update the alarm time if the alarm is not already set.
    */
    func updateAlarmTimePicker(date: NSDate) {
        if !alarm! {
            alarmTimePicker.date = date
            updateAlarmTime(date: date)
        }
    }
    
    
    /*
        @brief Number of sections in table view.
    */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    

    /*
        @brief Performs actions based on selected index path.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("***Selected: \(indexPath.section)\t\(indexPath.row)")
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        
        selectedIndexPath = indexPath
        // Take action based on what section was chosen
        switch indexPath.section {
        case sections["Name"]!:
            nameTextField.userInteractionEnabled = true
            nameTextField.becomeFirstResponder()
        case sections["Start"]!:
            tableView.beginUpdates()
            
            // Hide date start labels
            dateStartMainLabel.hidden = true
            dateStartDetailsLabel.hidden = true
            
            // Recalculate height to show date start picker
            eventDateStartCellHeight = dateStartPicker.frame.height
            
            // Show date start picker
            cell.contentView.addSubview(dateStartPicker)
            cell.contentView.didAddSubview(dateStartPicker)
            
            tableView.endUpdates()
        case sections["End"]!:
            tableView.beginUpdates()
            
            // Hide date end labels
            dateEndMainLabel.hidden = true
            dateEndDetailsLabel.hidden = true
            
            // Recalculate height to show date end picker
            eventDateEndCellHeight = dateEndPicker.frame.height
            
            // Show date end picker
            cell.contentView.addSubview(dateEndPicker)
            cell.contentView.didAddSubview(dateEndPicker)
            
            tableView.endUpdates()
        case sections["Contacts"]!:
            let contactsViewController = ABPersonViewController()
            self.navigationController?.pushViewController(contactsViewController, animated: true)
        default:
            break
        }
    }
    
    
    /*
        @brief On alarm switch toggle, show more or less options.
    */
    @IBAction func toggleAlarmOptions(sender: AnyObject) {
        if let alarmToggle = sender as? UISwitch {
            // On alarm switch press, deselect current selection
            if selectedIndexPath != nil && selectedIndexPath != indexPaths["AlarmToggle"] {
                deselectRowAtIndexPath(selectedIndexPath!)
            }
            selectedIndexPath = indexPaths["AlarmToggle"]
            
            alarm = alarmToggle.on
            if alarmToggle.on {
                showMoreAlarmOptions()
            }
            else {
                showFewerAlarmOptions()
                updateAlarmTimePicker(dateStart!)
            }
        }
    }
    
    
    /*
        @brief Shows more alarm options
    */
    func showMoreAlarmOptions() {
        println("***MORE***")
        tableView.beginUpdates()
        
        // Set cell heights
        alarmDateToggleCellHeight = DEFAULT_CELL_HEIGHT
        alarmTimeDisplayCellHeight = DEFAULT_CELL_HEIGHT
        alarmTimePickerCellHeight = PICKER_CELL_HEIGHT
        
        // Show options
        alarmDateToggleCell!.hidden = false
        alarmTimeDisplayCell!.hidden = false
        alarmTimePickerCell!.hidden = false
        
        tableView.endUpdates()
    }
    
    
    /*
        @brief Shows fewer alarm options
    */
    func showFewerAlarmOptions() {
        println("***LESS***")
        tableView.beginUpdates()
        
        // Get alarm options cells
        let alarmDateToggleCell = tableView.cellForRowAtIndexPath(indexPaths["AlarmDateToggle"]!)
        let alarmTimeDisplayCell = tableView.cellForRowAtIndexPath(indexPaths["AlarmTimeDisplay"]!)
        let alarmTimePickerCell = tableView.cellForRowAtIndexPath(indexPaths["AlarmTimePicker"]!)
        
        // Set cell heights to 0
        alarmDateToggleCellHeight = 0
        alarmTimeDisplayCellHeight = 0
        alarmTimePickerCellHeight = 0
        
        // Hide options
        alarmDateToggleCell!.hidden = true
        alarmTimeDisplayCell!.hidden = true
        alarmTimePickerCell!.hidden = true
        
        tableView.endUpdates()
    }
    
    
    @IBAction func updateName() {
        name = nameTextField.text
    }
    
    
    @IBAction func updateAlarmTime(sender: AnyObject) {
        alarmTime = alarmTimePicker.date
        updateAlarmTimeDisplay(alarmTime!)
    }
    
    
    func updateAlarmTime(#date: NSDate) {
        alarmTime = alarmTimePicker.date
        updateAlarmTimeDisplay(alarmTime!)
    }

    
    /*
        @brief Update alarm time display.
    */
    func updateAlarmTimeDisplay(date: NSDate) {
        // Main label shows format: month day, year
        dateFormatter.dateFormat = "MMM dd, yyyy"
        alarmTimeMainLabel.text = dateFormatter.stringFromDate(date)
        
        dateFormatter.dateFormat = "h:mm a"
        alarmTimeDetailsLabel.text = dateFormatter.stringFromDate(date)
    }
    
    
    // Called on cell deselection (when a different cell is selected)
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        println("***Deselected: \(indexPath.section)\t\(indexPath.row)***")
        deselectRowAtIndexPath(indexPath)
    }
    
    
    /*
        @brief Performs deselection of the field.
    */
    func deselectRowAtIndexPath(indexPath: NSIndexPath) {
        switch indexPath.section {
            // If deselecting event name field, text field stops being first responder and disables
            // user interaction with it.
        case sections["Name"]!:
            nameTextField.userInteractionEnabled = false
            nameTextField.resignFirstResponder()
            // If deselecting date start field, hide date start picker and show labels
        case sections["Start"]!:
            tableView.beginUpdates()
            
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            dateStartPicker.removeFromSuperview()
            eventDateStartCellHeight = DEFAULT_CELL_HEIGHT
            
            dateStartMainLabel.hidden = false
            dateStartDetailsLabel.hidden = false
            
            tableView.endUpdates()
            // If deselecting date end field, hide date end picker and show labels
        case sections["End"]!:
            tableView.beginUpdates()
            
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            dateEndPicker.removeFromSuperview()
            eventDateEndCellHeight = DEFAULT_CELL_HEIGHT
            
            dateEndMainLabel.hidden = false
            dateEndDetailsLabel.hidden = false
            
            tableView.endUpdates()
        default:
            break
        }
        selectedIndexPath = nil
    }
    
    
    // Calculates height for rows
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        // Event name field has default height
        case sections["Name"]!:
            return eventNameCellHeight
        // Event date start field changes height based on if it is selected or not
        case sections["Start"]!:
            return eventDateStartCellHeight
        // Event date end field changes height based on if it is selected or not
        case sections["End"]!:
            return eventDateEndCellHeight
        case sections["Alarm"]!:
            switch indexPath.row {
            // Alarm toggle height
            case indexPaths["AlarmToggle"]!.row:
                return alarmToggleCellHeight
            // Use date toggle height
            case indexPaths["AlarmDateToggle"]!.row:
                return alarmDateToggleCellHeight
            // Alarm time display height
            case indexPaths["AlarmTimeDisplay"]!.row:
                return alarmTimeDisplayCellHeight
            // Alarm time picker height
            case indexPaths["AlarmTimePicker"]!.row:
                return alarmTimePickerCellHeight
            default:
                return DEFAULT_CELL_HEIGHT
            }
        default:
            return DEFAULT_CELL_HEIGHT
        }
    }
    
    
    /*
        @brief Saves an event's data.
    */
    func saveEvent() -> NSManagedObject {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let entity = NSEntityDescription.entityForName("TestEvent", inManagedObjectContext: managedContext)!
        
        // Create event if it is a new event being created, otherwise just overwrite old data.
        if event == nil {
            event = NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedContext)
        }
        
        // Set data
        event!.setValue(name, forKey: "name")
        event!.setValue(dateStart, forKey: "dateStart")
        event!.setValue(dateEnd, forKey: "dateEnd")
        event!.setValue(alarm, forKey: "alarm")
        if alarm! {
            event!.setValue(alarmTime, forKey: "alarmTime")
        }
        
        // Save event
        var error: NSError?
        if !managedContext.save(&error) {
            assert(false, "Could not save \(error), \(error?.userInfo)")
        }
        
        return event!
    }
    
    
    /*
        @brief Prepares information for unwind segues.
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "SaveEventSegue":
                let event = saveEvent()
                delegate?.changeEventViewControllerDidSaveEvent(event)
            case "CancelEventSegue":
                break
            case "SaveEventEditSegue":
                let event = saveEvent()
                delegate?.changeEventViewControllerDidSaveEvent(event)
            case "CancelEventEditSegue":
                break
            default:
                break
            }
        }
    }
}


// Delegate protocol
protocol ChangeEventViewControllerDelegate {
    func changeEventViewControllerDidSaveEvent(event: NSManagedObject)
}
