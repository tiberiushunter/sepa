//
//  DashboardViewController.swift
//  SEPA
//
//  Created by Welek Samuel on 28/05/2017.
//  Copyright © 2017 Welek Samuel. All rights reserved.
//

import UIKit
import MapKit

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate  {
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    let locationManager = CLLocationManager()
    var coords = CLLocationCoordinate2D(latitude: 53.4846, longitude: -2.2708)
    
    var weatherSummary = ""
    var weatherIcon = WeatherIcon.nothing
    
    var plantSummary = ""
    var plantData: Array<PlantsModel> = []
    
    let reuseIdentifier = "tableViewCell"
    
    var lastCalc = 0.00
    var lastLong = 0.00
    var lastLat = 0.00
    var lastConv = 0.00
    var lastConvUnit = ""
    
    var appTitles = ["My Weather", "My News", "My Plants", "My Location History", "My Calculator", "My Converter", "My Settings"]
    
    var appSummaries = ["", "", "", "", "", "", "Adjust Sepa for your needs"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        tableView.dataSource = self
        tableView.delegate = self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        self.getPlantData() { jsonString in
            
            let jsonStr = jsonString as String
            let json: AnyObject? = jsonStr.parseJSONString
            
            for i in 0 ..< json!.count {
                let data = PlantsModel(
                    timestamp: json![i]["Timestamp"] as! String,
                    ambientLight: json![i]["AmbientLight"] as! String,
                    externalLight: json![i]["ExternalLight"] as! String,
                    soilMoisture: json![i]["SoilMoisture"] as! String,
                    hardwareTemperature: json![i]["HardwareTemperature"] as! String,
                    externalTemperature: json![i]["ExternalTemperature"] as! String,
                    ambientHumidity: json![i]["AmbientHumidity"] as! String,
                    ambientTemperature: json![i]["AmbientTemperature"] as! String
                )
                self.plantData.append(data)
            }
            dispatch_async(dispatch_get_main_queue()){
                if(Double(self.plantData[0].getSoilMoisture())! < 90.0){
                    self.plantSummary = "Plant Needs Watering!"
                } else{
                    self.plantSummary = "Plant doesn't need watering."
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus){
        if (status == .AuthorizedAlways){
            updateWeatherData()
        } else if (status == .Denied){
            let alert = UIAlertController(title: "Error", message: "Goto Settings and allow this app to access your location", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func getLocation(){
        if let loc = locationManager.location?.coordinate{
            coords = loc
        }
    }
    
    func getWeather(completion: (NSString) -> ()) {
        let urlPath = WeatherURL(lat: String(coords.latitude), long: String(coords.longitude)).getFullURL()
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        
        request.HTTPMethod = "GET"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            let jsonString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            
            completion(jsonString!)
        })
        task.resume()
    }
    
    func getPlantData(completion: (NSString) -> ()) {
        let urlPath = PlantApi().getFullURL()
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(URL: url)
        
        let session = NSURLSession.sharedSession()
        
        request.HTTPMethod = "GET"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            let jsonString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            
            completion(jsonString!)
            
        })
        task.resume()
    }
    
    func updateWeatherData(){
        getLocation()
        getWeather { jsonString in
            if let jsonDictionary = Utilities().convertStringToDictionary(jsonString as String){
                if let currently = jsonDictionary["currently"] as? Dictionary<String, AnyObject>{
                    if let sum = currently["summary"] as? String {
                        self.weatherSummary = sum
                    }
                    if let imageIcon = currently["icon"] as? String {
                        switch(imageIcon){
                        case "clear-day": self.weatherIcon = WeatherIcon.clearDay
                        case "clear-night": self.weatherIcon = WeatherIcon.clearNight
                        case "rain": self.weatherIcon = WeatherIcon.rain
                        case "snow": self.weatherIcon = WeatherIcon.snow
                        case "sleet": self.weatherIcon = WeatherIcon.snow
                        case "wind": self.weatherIcon = WeatherIcon.wind
                        case "fog": self.weatherIcon = WeatherIcon.fog
                        case "cloudy": self.weatherIcon = WeatherIcon.cloudy
                        case "partly-cloudy-day": self.weatherIcon = WeatherIcon.partlyCloudyDay
                        case "partly-cloudy-night": self.weatherIcon = WeatherIcon.partlyCloudyNight
                        case "hail": self.weatherIcon = WeatherIcon.rain
                        case "thunderstorm": self.weatherIcon = WeatherIcon.thunderstorm
                        case "tornado": self.weatherIcon = WeatherIcon.tornado
                        default: self.weatherIcon = WeatherIcon.nothing
                        }
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool){
        super.viewWillAppear(animated)
        lastCalc = (NSUserDefaults.standardUserDefaults().doubleForKey("lastCalc"))
        lastLat = (NSUserDefaults.standardUserDefaults().doubleForKey("lastLat"))
        lastLong = (NSUserDefaults.standardUserDefaults().doubleForKey("lastLong"))
        lastConv = (NSUserDefaults.standardUserDefaults().doubleForKey("lastConv"))
        
        if(NSUserDefaults.standardUserDefaults().objectForKey("lastConvUnit") != nil){
            lastConvUnit = (NSUserDefaults.standardUserDefaults().objectForKey("lastConvUnit")as! String!)
        }
        
        tableView.reloadData()
        
    }

    @IBAction func editButtonAction(sender: AnyObject) {
        if(editButton.title == "Edit"){
            editButton.title = "Done"
        } else{
            editButton.title = "Edit"
        }
        tableView.editing = !tableView.editing
       
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true}
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        var itemToMove = appTitles[fromIndexPath.row]
        appTitles.removeAtIndex(fromIndexPath.row)
        appTitles.insert(itemToMove, atIndex: toIndexPath.row)
        
        itemToMove = appSummaries[fromIndexPath.row]
        appSummaries.removeAtIndex(fromIndexPath.row)
        appSummaries.insert(itemToMove, atIndex: toIndexPath.row)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: DashboardTableViewCell = (tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? DashboardTableViewCell)!
        
        cell.title.text = appTitles[indexPath.row]
        cell.summary.text = appSummaries[indexPath.row]
        switch (cell.title.text!){
        case "My Weather":
            if(self.weatherIcon != WeatherIcon.nothing){
                cell.dashboardIcon.image = UIImage(named: self.weatherIcon.rawValue)
            }
            
            cell.summary.text = "Summary: " + weatherSummary
            case "My News":
                cell.dashboardIcon.image = UIImage(named: "dashboard-news")
            case "My Plants":
                cell.dashboardIcon.image = UIImage(named: "dashboard-plants")
                cell.summary.text = plantSummary
            case "My Location History":
                cell.dashboardIcon.image = UIImage(named: "dashboard-locationhistory")
                if (lastLat == 0.00 && lastLong == 0.00){
                    cell.summary.text = "Add a marker to set past location."
                }
                else{
                cell.summary.text = "Lat = \(Double(lastLat)) Long = \(Double(lastLong))"
            }
            case "My Calculator":
                cell.dashboardIcon.image = UIImage(named: "dashboard-calculator")
                cell.summary.text = "Last Result = \(Double(lastCalc))"
            case "My Converter":
                cell.dashboardIcon.image = UIImage(named: "dashboard-converter")
                cell.summary.text = "Last Result = \(Double(lastConv))" + lastConvUnit
            case "My Settings":
                cell.dashboardIcon.image = UIImage(named: "dashboard-settings")
        default:
            cell.dashboardIcon.image = UIImage(named: "dashboard-calculator")
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! DashboardTableViewCell
    
        switch(cell.title.text!){
            case "My Weather" : performSegueWithIdentifier("showWeather", sender: indexPath)
            case "My News" : performSegueWithIdentifier("showNews", sender: indexPath)
            case "My Plants" : performSegueWithIdentifier("showPlants", sender: indexPath)
            case "My Location History" : performSegueWithIdentifier("showLocationHistory", sender: indexPath)
            case "My Calculator" : performSegueWithIdentifier("showCalculator", sender: indexPath)
            case "My Converter" : performSegueWithIdentifier("showConverter", sender: indexPath)
            case "My Settings" : performSegueWithIdentifier("showSettings", sender: indexPath)
            default : break
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appTitles.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "My Dashboard Apps"
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
