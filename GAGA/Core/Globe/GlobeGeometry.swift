//
//  GlobeGeometry.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import Foundation
import SceneKit

class GlobeGeometry {
    static func createGlobe(radius: CGFloat = 1.0) -> SCNSphere {
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 96
        return sphere
    }

    // 国境線をノードとして生成
    static func createCountryBorders(countries: [Country], radius: CGFloat = 1.01) -> SCNNode {
        let borderNode = SCNNode()
        borderNode.name = "borders"

        for country in countries {
            guard let geometry = country.geometry else { continue }

            // TODO: GeoJSON geometryからSCNShapeを生成
            // 国境線をベジェパスとして描画し、3D球面に投影
        }

        return borderNode
    }

    // GeoJSONの座標を球面上の3D座標に変換
    static func geoCoordinatesToVector3(lon: Double, lat: Double, radius: CGFloat) -> SCNVector3 {
        let latRad = lat * .pi / 180.0
        let lonRad = lon * .pi / 180.0

        let x = CGFloat(cos(latRad) * cos(lonRad)) * radius
        let y = CGFloat(sin(latRad)) * radius
        let z = CGFloat(cos(latRad) * sin(lonRad)) * radius

        return SCNVector3(x, y, -z)
    }
}
