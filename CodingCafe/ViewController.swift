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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        self.getCafeCoordinate()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
            
        else if CLLocationManager.authorizationStatus() == .denied {
            
            let alertController = UIAlertController(
                title: "請開啟定位權限",
                message:"如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler: nil)
            alertController.addAction(okAction)
            show(alertController, sender: self)
            
        }
            
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
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
        
        
        Alamofire.request(API).responseJSON { (response) in
            switch response.result.isSuccess {
            case true:
                
                if let value = response.result.value {
                    
                    let json = JSON(value)
                    DispatchQueue.global().async {
                        for (key,_):(String, JSON) in json {
                            let address = json[Int(key)!]["address"].string!
                            let city = json[Int(key)!]["city"].string!
                            let latitude = json[Int(key)!]["latitude"].string!
                            let longitude = json[Int(key)!]["longitude"].string!
                            let name = json[Int(key)!]["name"].string!
                            let wifi = json[Int(key)!]["wifi"].string ?? ""
                            
                            let array = [address,city,latitude,longitude,name,wifi]
                            
                            self.setupData(lat: latitude, long: longitude, name: name, address: address)
                        }
                    }
                }
            case false:
                print("error: \(response.result.error)")
            }
        }
    }
    
    func setupData(lat: String, long: String, name: String, address: String) {
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self){
             
                let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(lat)!, CLLocationDegrees(long)!)
                
                let cafeAnnotation = MKPointAnnotation()
                cafeAnnotation.coordinate = coordinate
                cafeAnnotation.title = name
                cafeAnnotation.subtitle = address
                
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
        
        let btn_Navigation = UIButton(type: .detailDisclosure)
        btn_Navigation.titleLabel?.text = "導航"
        btn_Navigation.addTarget(self, action: #selector(btn_NavigationPress), for: .touchUpInside)
        cafeAnnotation?.rightCalloutAccessoryView = btn_Navigation
        
        cafeAnnotation?.canShowCallout = true
        
        return cafeAnnotation
    }
    
    func btn_NavigationPress () {
        
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
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        selectAnnLocation = view.annotation!.coordinate
        annationTitle = view.annotation!.title!
    }
    
}

