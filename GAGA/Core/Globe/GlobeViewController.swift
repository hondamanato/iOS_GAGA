//
//  GlobeViewController.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import SceneKit
import CoreLocation

class GlobeViewController: ObservableObject {
    @Published var selectedCountry: Country?
    @Published var cameraDistance: Float = 3.0

    // 緯度経度から3D座標に変換（SceneKitのテクスチャマッピングに合わせた座標系）
    func latLonToVector3(lat: Double, lon: Double, radius: Float = 1.0) -> SCNVector3 {
        let latRad = lat * .pi / 180.0
        let lonRad = lon * .pi / 180.0

        // SceneKitのSCNSphereでは、経度0°が+Z軸方向になる
        let x = Float(cos(latRad) * sin(lonRad)) * radius
        let y = Float(sin(latRad)) * radius
        let z = Float(cos(latRad) * cos(lonRad)) * radius

        return SCNVector3(x, y, z)
    }

    // 3D座標から緯度経度に変換（SceneKitの座標系に対応）
    func vector3ToLatLon(_ vector: SCNVector3) -> CLLocationCoordinate2D {
        let radius = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)

        let lat = asin(vector.y / radius) * 180.0 / .pi
        let lon = atan2(vector.x, vector.z) * 180.0 / .pi

        return CLLocationCoordinate2D(latitude: Double(lat), longitude: Double(lon))
    }

    // カメラを特定の国にズーム
    func zoomToCountry(_ country: Country, cameraNode: SCNNode, duration: TimeInterval = 1.0) {
        guard let bbox = country.boundingBox else { return }

        let center = bbox.center
        let position = latLonToVector3(lat: center.lat, lon: center.lon, radius: 2.5)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        cameraNode.position = position
        SCNTransaction.commit()
    }
}
