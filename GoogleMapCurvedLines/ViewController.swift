//
//  ViewController.swift
//  GoogleMapCurvedLines
//
//  Created by Samantha on 2020/2/20.
//  Copyright © 2020 Samantha. All rights reserved.
//  source: https://www.appcoda.com.tw/google-maps-curved-lines/

import UIKit
import GoogleMaps

class ViewController: UIViewController {

    @IBOutlet private weak var mapView: GMSMapView!
    private var polylines: [GMSPolyline] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleTheMap()
        
        let london = CLLocationCoordinate2D(latitude: 51.5287714, longitude: -0.2420222)
        let cambridge = CLLocationCoordinate2D(latitude: 52.1988895, longitude: 0.0848821)
        
        clearCurvedPolylines()
        draw(startLocation: london, endLocation: cambridge)
    }
    
    func loadContentFile(name:String, type:String) -> String? {
        do {
            let filePath = Bundle.main.path(forResource: name, ofType: type)
            let fileContent = try String(contentsOfFile: filePath!, encoding: String.Encoding.utf8) as String?
            return fileContent
        } catch let error {
            print("json serialization error: \(error)")
            return nil
        }
    }
    
    func styleTheMap() {
        mapView.mapStyle = try! GMSMapStyle(jsonString: loadContentFile(name: "mapStyle", type: "json")!)
    }
    
    func draw(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D) {
        let polyline = getPolyline(startLocation: startLocation, endLocation: endLocation)!
        polylines.append(polyline)
    }
    
    /// Return a polyline from startLocation to endLocation
    /// - Parameters:
    ///   - startLocation: coordinate must be valid
    ///   - endLocation: coordinate must be valid
    func getPolyline(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D) -> GMSPolyline? {
        //Create initial path
        let path = GMSMutablePath()
        
        //STEP 1: 計算兩點間的距離
        //Google Maps 可支援透過 GMSGeometryDistance 函式，獲取地圖上 2 個點之間的距離（單位為公尺）。
        let SE = GMSGeometryDistance(startLocation, endLocation)
        
        //STEP 2: 定義合適的角度
        //如果角度太大，O（中心點）與 S 或 E 的距離可能會很遠，這樣曲線看起來就會像一條直線，
        //角度是小於 Pi / 2。角度越小，曲線就可以更彎曲。
        let angle = Double.pi / 2

        //STEP 3:利用公式，計算半徑和 M 與 O 點的距離
        let ME = SE / 2.0
        let R = ME / sin(angle / 2)
        let MO = R * cos(angle / 2)
        
        //STEP 4: 計算O的座標
        //GMSGeometryHeading: 回傳從 from 以最短路徑航向 to 的初始 heading（從北往順時針方向的度數）
        //而回傳值在 [0, 360) 的範圍內。
        //從開始位置到結束位置
        let heading = GMSGeometryHeading(startLocation, endLocation)
        //當從 from 的初始 heading 開始，沿地球的大圓弧前進特定 distance 後，這個方法會回傳目的地座標。而回傳的經度在 [-180, 180) 範圍內
        //由於 S、M、E 在同一條線上，因此我們可以透過以下方式找到 M 的座標
        let mCoordinate = GMSGeometryOffset(startLocation, ME, heading)
        //透過一個基於 S 經度和 E 經度的公式來選擇方向
        let direction = (startLocation.longitude - endLocation.longitude > 0) ? -1.0 : 1.0
        let angleFromCenter = 90.0 * direction
        //計算 O 的座標
        let oCoordinate = GMSGeometryOffset(mCoordinate, MO, heading + angleFromCenter)
        addMarkerOnMap(location: startLocation)

        //Add endLocation to the path
        path.add(endLocation)
        
        //Add marker for endLocation
        addMarkerOnMap(location: endLocation)
        
        
        //STEP 5: 在曲線上找到不同角度 (a1、a2、⋯ an) 的各個位置
        //需要將角度分割成 n 個較小的角度，然後結合 半徑 和 O 座標 的資料，來找到曲線上每個點的座標
        let num = 100
        
        let initialHeading = GMSGeometryHeading(oCoordinate, endLocation)
        let degree = (180.0 * angle) / Double.pi
        
        ////定義曲線上的每個位置：計算每個位置座標，並將它們添加到上面創建的初始路徑中
        for i in 1...num {
            let step = Double(i) * (degree / Double(num))
            let heading : Double = (-1.0) * direction
            let pointOnCurvedLine = GMSGeometryOffset(oCoordinate, R, initialHeading + heading * step)
            path.add(pointOnCurvedLine)
        }
        
        path.add(startLocation)
        addMarkerOnMap(location: startLocation)
        
        //Adjust polylines are in the center of the screen
        let bounds = GMSCoordinateBounds(path: path)
        mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50))
        
        //STEP 6: 將 GMSMutablePath 轉換為 GMSPolyline
        let polyline = GMSPolyline(path: path)
        //將其添加到地圖視圖中
        polyline.map = mapView
        //設置線的寬度和顏色
        polyline.strokeWidth = 4.0
        polyline.strokeColor = UIColor.white
        
        return polyline
    }
    
    func clearCurvedPolylines() {
        for polyline in polylines {
            polyline.map = nil
        }
        polylines.removeAll()
    }
    
    func addMarkerOnMap(location: CLLocationCoordinate2D){
        let marker = GMSMarker(position: location)
        marker.icon = UIImage(named: "ic_pin")
        marker.map = mapView
    }
}


