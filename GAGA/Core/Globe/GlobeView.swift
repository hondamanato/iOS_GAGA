//
//  GlobeView.swift
//  GAGA
//
//  Created by AI on 2025/10/09.
//

import SwiftUI
import SceneKit

struct GlobeView: UIViewRepresentable {
    @Binding var selectedCountry: Country?
    @Binding var selectedPhoto: Photo?
    @Binding var showPhotoDetail: Bool
    var photos: [String: Photo] = [:] // countryCode -> Photo

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()

        // 地球儀作成
        let globe = SCNSphere(radius: 1.0)
        globe.segmentCount = 96

        // ベースマテリアル（海の色）
        let baseMaterial = SCNMaterial()
        baseMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0) // 海の青色
        baseMaterial.specular.contents = UIColor.white
        baseMaterial.shininess = 0.1
        baseMaterial.lightingModel = .constant // 影を削除（均一な明るさ）
        globe.materials = [baseMaterial]

        let globeNode = SCNNode(geometry: globe)
        globeNode.name = "globe"
        scene.rootNode.addChildNode(globeNode)

        // カメラ設定
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 3)
        scene.rootNode.addChildNode(cameraNode)

        // ライト設定
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(2, 2, 2)
        scene.rootNode.addChildNode(lightNode)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = UIColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // 星空背景を設定
        if let starfield = UIImage(named: "starfield") {
            print("✅ Starfield image loaded successfully")
            scene.background.contents = starfield
            scene.background.intensity = 0.6 // 明るさ調整（0.5〜1.0で調整可能）
        } else {
            print("❌ Failed to load starfield image")
            print("📁 Checking alternative names...")
            // 拡張子付きで試す
            if let starfieldWithExt = UIImage(named: "starfield.jpg") {
                print("✅ Starfield image loaded with .jpg extension")
                scene.background.contents = starfieldWithExt
                scene.background.intensity = 0.6
            }
        }

        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = UIColor.black
        sceneView.autoenablesDefaultLighting = false

        // タップジェスチャー追加
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        context.coordinator.sceneView = sceneView

        // 国境線を追加（テクスチャベースに変更したため無効化）
        // context.coordinator.addCountryBorders(to: scene)

        return sceneView
    }

    func updateUIView(_ sceneView: SCNView, context: Context) {
        // 写真の更新があればテクスチャを更新
        context.coordinator.updatePhotos(photos)

        // 選択された国のハイライトを更新
        context.coordinator.updateHighlight(for: selectedCountry, in: sceneView.scene)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            selectedCountry: $selectedCountry,
            selectedPhoto: $selectedPhoto,
            showPhotoDetail: $showPhotoDetail,
            photos: photos
        )
    }

    class Coordinator: NSObject {
        @Binding var selectedCountry: Country?
        @Binding var selectedPhoto: Photo?
        @Binding var showPhotoDetail: Bool
        weak var sceneView: SCNView?

        // 差分更新用：既存のテクスチャと写真リストを保持
        private var currentTexture: UIImage?
        private var currentPhotos: [String: Photo] = [:]

        // タップ時に写真を検出するために保持
        private var photos: [String: Photo] = [:]

        init(selectedCountry: Binding<Country?>, selectedPhoto: Binding<Photo?>, showPhotoDetail: Binding<Bool>, photos: [String: Photo]) {
            self._selectedCountry = selectedCountry
            self._selectedPhoto = selectedPhoto
            self._showPhotoDetail = showPhotoDetail
            self.photos = photos
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = sceneView else { return }

            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [:])

            if let hit = hitResults.first {
                let hitPoint = hit.worldCoordinates
                print("🎯 Tapped at 3D coordinates: (\(hitPoint.x), \(hitPoint.y), \(hitPoint.z))")

                // CountryDetectorを使って国を特定
                let country = CountryDetector.shared.detectCountryFromVector(
                    x: hitPoint.x,
                    y: hitPoint.y,
                    z: hitPoint.z
                )

                if let country = country {
                    print("🌍 Selected country: \(country.name) (\(country.id))")

                    // その国に写真があるかチェック
                    if let photo = photos[country.id] {
                        print("📸 Photo found for \(country.name), showing detail view")
                        selectedPhoto = photo
                        showPhotoDetail = true
                    } else {
                        print("ℹ️ No photo for \(country.name), selecting country")
                        selectedCountry = country
                    }
                } else {
                    print("🌊 Tapped on ocean or unrecognized area")
                    selectedCountry = nil
                }
            }
        }

        func updatePhotos(_ photos: [String: Photo]) {
            guard let scene = sceneView?.scene else { return }

            // タップ検出用に写真リストを更新
            self.photos = photos

            print("📸 Updating photos on globe: \(photos.count) countries")

            // 既存の写真ノード削除（旧方式との互換性のため）
            scene.rootNode.childNodes
                .filter { $0.name?.starts(with: "photo_") == true }
                .forEach { $0.removeFromParentNode() }

            // Equirectangularテクスチャを使用
            Task { @MainActor in
                await updateGlobeTexture(photos: photos, scene: scene)
            }
        }

        @MainActor
        private func updateGlobeTexture(photos: [String: Photo], scene: SCNScene) async {
            // 初回は必ずテクスチャを作成
            let isFirstTime = currentTexture == nil

            // 写真リストの変更を検出（追加・削除・変更すべてを含む）
            let photosChanged = photos.count != currentPhotos.count ||
                                !photos.allSatisfy { countryCode, photo in
                                    currentPhotos[countryCode]?.id == photo.id
                                }

            if !photosChanged && !isFirstTime {
                print("ℹ️ No changes in photos")
                return
            }

            // 新規追加・変更された写真
            let newPhotos = photos.filter { countryCode, photo in
                currentPhotos[countryCode]?.id != photo.id
            }

            // 削除された写真
            let deletedCountries = currentPhotos.keys.filter { !photos.keys.contains($0) }

            print("📸 Photos changed: \(newPhotos.count) new/updated, \(deletedCountries.count) deleted (total: \(photos.count) countries)")

            // 全国データを取得
            let allCountries = GeoDataManager.shared.getAllCountries()
            var countriesDict: [String: Country] = [:]
            for country in allCountries {
                countriesDict[country.id] = country
            }

            // 差分更新 or 全体再生成
            let photoAtlas: UIImage?

            if photos.isEmpty {
                // 写真がない場合：白い国境だけのベーステクスチャを作成
                print("🗺 Creating base texture with white countries (no photos)...")
                let equirectangular = EquirectangularTexture(textureSize: CGSize(width: 2048, height: 1024))
                let baseTexture = equirectangular.getCurrentTexture() ?? UIImage()
                photoAtlas = equirectangular.drawCountriesToTexture(baseTexture)
            } else if let existingTexture = currentTexture,
                      newPhotos.count < 3 && deletedCountries.isEmpty {
                // 差分更新：新しい写真だけを既存テクスチャに追加（削除がない場合のみ）
                print("🔄 Performing incremental update for \(newPhotos.count) photos...")
                photoAtlas = await updateTextureIncrementally(
                    baseTexture: existingTexture,
                    newPhotos: newPhotos,
                    countries: countriesDict
                )
            } else {
                // 全体再生成：初回、多数の写真が追加された場合、または削除があった場合
                if !deletedCountries.isEmpty {
                    print("🔄 Performing full texture regeneration due to \(deletedCountries.count) deletion(s)...")
                } else {
                    print("🔄 Performing full texture regeneration...")
                }
                photoAtlas = await GlobeMaterial.createPhotoAtlas(
                    photos: photos,
                    countries: countriesDict
                )
            }

            guard let finalTexture = photoAtlas else {
                print("❌ Failed to create photo atlas")
                return
            }

            print("✅ Photo atlas created, applying to globe...")

            // 球体のマテリアルを更新
            if let globeNode = scene.rootNode.childNode(withName: "globe", recursively: false),
               let sphere = globeNode.geometry as? SCNSphere {

                // 新しいマテリアルを作成
                let material = SCNMaterial()
                material.diffuse.contents = finalTexture
                material.specular.contents = UIColor.white
                material.shininess = 0.1
                material.lightingModel = .constant // 影を削除（均一な明るさ）
                material.isDoubleSided = false

                // マテリアルを適用
                sphere.materials = [material]

                // 状態を更新
                currentTexture = finalTexture
                currentPhotos = photos

                print("🎉 Globe texture updated successfully with \(photos.count) photos!")
            } else {
                print("⚠️ Globe node not found")
            }
        }

        // 差分更新用：新しい写真だけを既存テクスチャに追加
        @MainActor
        private func updateTextureIncrementally(
            baseTexture: UIImage,
            newPhotos: [String: Photo],
            countries: [String: Country]
        ) async -> UIImage? {
            var texture = baseTexture

            for (countryCode, photo) in newPhotos {
                guard let country = countries[countryCode] else {
                    print("⚠️ Country not found: \(countryCode)")
                    continue
                }

                // 写真をダウンロード（NetworkManagerを使用してキャッシュ対応）
                guard let image = try? await NetworkManager.shared.downloadImage(from: photo.imageURL) else {
                    print("❌ Failed to download image for \(countryCode)")
                    continue
                }

                // 写真をテクスチャに追加
                if let updatedTexture = GlobeMaterial.addPhotoToTexture(
                    texture,
                    photo: image,
                    country: country
                ) {
                    texture = updatedTexture
                    print("✅ Incrementally added photo for \(country.name)")
                }
            }

            return texture
        }

        // 旧方式のaddPhotoToGlobeは削除（Equirectangularテクスチャ方式に完全移行）

        func updateHighlight(for country: Country?, in scene: SCNScene?) {
            guard let scene = scene else { return }

            // 既存のハイライトを削除
            scene.rootNode.childNodes.filter { $0.name?.starts(with: "highlight_") == true }.forEach { $0.removeFromParentNode() }

            // 新しい国が選択されている場合、ハイライトを追加
            guard let country = country, let geometry = country.geometry else { return }

            for ring in geometry.coordinates {
                guard ring.count >= 2 else { continue }

                var vertices: [SCNVector3] = []

                for point in ring {
                    guard point.count >= 2 else { continue }
                    let lon = point[0]
                    let lat = point[1]

                    // 緯度経度を3D座標に変換（地表と同じ位置）
                    let vector = latLonToVector3(lat: lat, lon: lon, radius: 1.0)
                    vertices.append(vector)
                }

                if vertices.count >= 2 {
                    // ラインジオメトリを作成
                    let sources = SCNGeometrySource(vertices: vertices)

                    var indices: [Int32] = []
                    for i in 0..<(vertices.count - 1) {
                        indices.append(Int32(i))
                        indices.append(Int32(i + 1))
                    }

                    let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
                    let element = SCNGeometryElement(
                        data: indexData,
                        primitiveType: .line,
                        primitiveCount: indices.count / 2,
                        bytesPerIndex: MemoryLayout<Int32>.size
                    )

                    let lineGeometry = SCNGeometry(sources: [sources], elements: [element])

                    // ハイライト用マテリアル（黄色の太い線）
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.systemYellow
                    material.lightingModel = .constant
                    lineGeometry.materials = [material]

                    let lineNode = SCNNode(geometry: lineGeometry)
                    lineNode.name = "highlight_\(country.id)"
                    lineNode.renderingOrder = 10 // 地球のテクスチャより後に描画
                    scene.rootNode.addChildNode(lineNode)
                }
            }

            print("🌟 Highlighted country: \(country.name)")
        }

        func addCountryBorders(to scene: SCNScene) {
            let countries = GeoDataManager.shared.getAllCountries()
            print("📍 Adding borders for \(countries.count) countries")

            for country in countries {
                guard let geometry = country.geometry else { continue }

                // 各ポリゴンリングをラインとして描画
                for ring in geometry.coordinates {
                    guard ring.count >= 2 else { continue }

                    var vertices: [SCNVector3] = []

                    for point in ring {
                        guard point.count >= 2 else { continue }
                        let lon = point[0]
                        let lat = point[1]

                        // 緯度経度を3D座標に変換（半径1.01で地球の表面より少し外側に配置）
                        let vector = latLonToVector3(lat: lat, lon: lon, radius: 1.01)
                        vertices.append(vector)
                    }

                    if vertices.count >= 2 {
                        // ラインジオメトリを作成
                        let sources = SCNGeometrySource(vertices: vertices)

                        var indices: [Int32] = []
                        for i in 0..<(vertices.count - 1) {
                            indices.append(Int32(i))
                            indices.append(Int32(i + 1))
                        }

                        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
                        let element = SCNGeometryElement(
                            data: indexData,
                            primitiveType: .line,
                            primitiveCount: indices.count / 2,
                            bytesPerIndex: MemoryLayout<Int32>.size
                        )

                        let lineGeometry = SCNGeometry(sources: [sources], elements: [element])

                        // マテリアル設定（黒い線）
                        let material = SCNMaterial()
                        material.diffuse.contents = UIColor(white: 0.0, alpha: 0.8)
                        material.lightingModel = .constant
                        lineGeometry.materials = [material]

                        let lineNode = SCNNode(geometry: lineGeometry)
                        lineNode.name = "border_\(country.id)"
                        scene.rootNode.addChildNode(lineNode)
                    }
                }
            }

            print("✅ Country borders added to globe")
        }

        // 緯度経度から3D座標に変換（SceneKitのテクスチャマッピングに合わせた座標系）
        private func latLonToVector3(lat: Double, lon: Double, radius: Float) -> SCNVector3 {
            let latRad = lat * .pi / 180.0
            let lonRad = lon * .pi / 180.0

            // SceneKitのSCNSphereでは、経度0°が+Z軸方向になる
            let x = Float(cos(latRad) * sin(lonRad)) * radius
            let y = Float(sin(latRad)) * radius
            let z = Float(cos(latRad) * cos(lonRad)) * radius

            return SCNVector3(x, y, z)
        }
    }
}

#Preview {
    GlobeView(
        selectedCountry: .constant(nil),
        selectedPhoto: .constant(nil),
        showPhotoDetail: .constant(false)
    )
}
