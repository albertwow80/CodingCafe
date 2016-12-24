//
//  ViewController.swift
//  CodingCafe
//
//  Created by 余佳恆 on 2016/12/20.
//  Copyright © 2016年 icdt. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON
import Alamofire


let API = "https://cafenomad.tw/api/v1.0/cafes"


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    
    var locationManager : CLLocationManager!
    var selectAnnLocation : CLLocationCoordinate2D?
    var currentLocation : CLLocationCoordinate2D?
    var annationTitle : String?
    
    var arrayTitle = [String]()
    var arrayDic = [Dictionary<String, String>]()
    var fbUrl = ""
    
    @IBOutlet var label_WIfi: UILabel!
    @IBOutlet var label_Seat: UILabel!
    @IBOutlet var label_Quiet: UILabel!
    @IBOutlet var label_Tasty: UILabel!
    @IBOutlet var label_Cheap: UILabel!
    @IBOutlet var label_Music: UILabel!
    @IBOutlet var label_Address: UILabel!
    @IBOutlet var label_Name: UILabel!
    
    @IBOutlet var btn_Navigation: UIButton!
    
    @IBOutlet var vc_Detail: UIView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        vc_Detail.isHidden = true
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        self.getCafeCoordinate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .denied {
            
            let alertController = UIAlertController(
                title: "請開啟定位權限",
                message:"如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler: nil)
            alertController.addAction(okAction)
            show(alertController, sender: self)
            
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        locationManager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getCafeCoordinate() {
       
        Alamofire.request(API, encoding: JSONEncoding.default).responseJSON { (response) in
            switch response.result.isSuccess {
            case true:
                
                if let value = response.result.value {
                    
                    DispatchQueue.global().async {
                        
                        let json = JSON(value)
                        
                        for (key,_):(String, JSON) in json {
                            
                            let dicValue = json[Int(key)!].dictionaryValue
                            var dicString : Dictionary<String, String> = [:]
                            dicValue.forEach { dicString[$0.0] = String(describing: $0.1) }
                            
//                            print("\(type(of: dicString)): \(dicString)")
                            self.arrayDic += [dicString]
                            self.arrayTitle += [json[Int(key)!]["name"].string ?? ""]
                            /*
                            let address = json[Int(key)!]["address"].string!
                            let latitude = json[Int(key)!]["latitude"].string!
                            let longitude = json[Int(key)!]["longitude"].string!
                            let name = json[Int(key)!]["name"].string ?? ""
                            let city = json[Int(key)!]["city"].string ?? ""
                            let url = json[Int(key)!]["url"].string ?? ""
                            let wifi = json[Int(key)!]["wifi"].string ?? ""
                            let seat = json[Int(key)!]["seat"].string ?? ""
                            let quiet = json[Int(key)!]["quiet"].string ?? ""
                            let tasty = json[Int(key)!]["tasty"].string ?? ""
                            let cheap = json[Int(key)!]["cheap"].string ?? ""
                            let music = json[Int(key)!]["music"].string ?? ""
                            
                            print(wifi,seat,quiet,tasty,cheap,music)
                            */
                            
                            self.setupData(dic: dicString)
                        }
                    }
                }
            case false:
                print("error: \(response.result.error)")
            }
        }
    }
    
    func setupData(dic: Dictionary<String, String>) {
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self){
             
                let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(dic["latitude"]!)!, CLLocationDegrees(dic["longitude"]!)!)
                
                let cafeAnnotation = MKPointAnnotation()
                cafeAnnotation.coordinate = coordinate
                cafeAnnotation.title = dic["name"]
//                cafeAnnotation.subtitle = dic["address"]
            
                
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(cafeAnnotation)
                }
        }
        else {
            print("System can't track regions")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let LoactionCoordinate = locations.last!.coordinate
        currentLocation = CLLocationCoordinate2D(latitude: LoactionCoordinate.latitude, longitude: LoactionCoordinate.longitude)
        let _span:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005);
        
        self.mapView.setRegion(MKCoordinateRegion(center: currentLocation!, span: _span), animated: true);

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        var cafeAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
        if cafeAnnotation == nil {
            cafeAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        }
        
//        let btn_Navigation = UIButton(type: .detailDisclosure)
//        btn_Navigation.addTarget(self, action: #selector(btn_NavigationPress), for: .touchUpInside)
//        cafeAnnotation?.rightCalloutAccessoryView = btn_Navigation
//        cafeAnnotation?.canShowCallout = true
        
        return cafeAnnotation
    }
    
    @IBAction func btn_NavigationPress () {
        
        let pA = MKPlacemark(coordinate: currentLocation!, addressDictionary: nil)
        let pB = MKPlacemark(coordinate: selectAnnLocation!, addressDictionary: nil)
        
        let miA = MKMapItem(placemark: pA)
        let miB = MKMapItem(placemark: pB)
        miA.name = "我的位置"
        miB.name = annationTitle
        
        let routes = [miA, miB]
        
        let opions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
        MKMapItem.openMaps(with: routes, launchOptions: opions)
   
    }
    
    @IBAction func btn_FBPress(_ sender: Any) {
        
        if UIApplication.shared.canOpenURL(URL(string: fbUrl)!) {
            UIApplication.shared.openURL(URL(string: "fb://profile/nurockplayer")!)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        selectAnnLocation = view.annotation!.coordinate
        annationTitle = view.annotation!.title!
        
        vc_Detail.isHidden = false
        var frame = mapView.frame
        frame.size.height = vc_Detail.frame.origin.y
        mapView.frame = frame
        
//        arrayDic.index(where: <#T##([String : String]) throws -> Bool#>)
        
        let indexNumber = arrayTitle.index(of: annationTitle!)
        
        let dic = arrayDic[indexNumber!]
        
        label_Name.text = dic["name"] ?? ""
        label_Name.sizeToFit()
        label_WIfi.text = dic["wifi"] ?? ""
        label_Seat.text = dic["seat"] ?? ""
        label_Quiet.text = dic["quiet"] ?? ""
        label_Tasty.text = dic["tasty"] ?? ""
        label_Cheap.text = dic["cheap"] ?? ""
        label_Music.text = dic["music"] ?? ""
        label_Address.text = dic["address"] ?? ""
        label_Address.sizeToFit()
//        btn_Navigation.frame.origin.x = label_Address.frame.maxX + 5
        fbUrl = dic["url"] ?? ""
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        vc_Detail.isHidden = true
        mapView.frame = self.view.frame
    }
}

