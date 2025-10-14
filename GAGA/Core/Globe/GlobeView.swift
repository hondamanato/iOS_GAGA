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

        // 宇宙背景球体を作成（巨大な球体の内側に星空を表示）
        let starfieldSphere = SCNSphere(radius: 50.0)
        starfieldSphere.segmentCount = 48

        let starfieldMaterial = SCNMaterial()
        if let starfield = UIImage(named: "starfield") ?? UIImage(named: "starfield.jpg") {
            starfieldMaterial.diffuse.contents = starfield
            starfieldMaterial.isDoubleSided = true // 内側も表示
            starfieldMaterial.cullMode = .front // 外側をカリング（内側だけ表示）
            starfieldMaterial.lightingModel = .constant // ライティングの影響を受けない
            print("✅ Starfield sphere created successfully")
        } else {
            // フォールバック：黒い背景
            starfieldMaterial.diffuse.contents = UIColor.black
            print("❌ Failed to load starfield image for sphere")
        }
        starfieldSphere.materials = [starfieldMaterial]

        let starfieldNode = SCNNode(geometry: starfieldSphere)
        starfieldNode.name = "starfield"
        scene.rootNode.addChildNode(starfieldNode)

        // 地球儀作成（背景球体の子ノードとして追加）
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
        starfieldNode.addChildNode(globeNode) // 背景球体の子ノードとして追加

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

        sceneView.scene = scene
        sceneView.allowsCameraControl = false // カスタム回転制御を使用
        sceneView.backgroundColor = UIColor.black
        sceneView.autoenablesDefaultLighting = false

        // タップジェスチャー追加
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        // パンジェスチャー追加（カスタム回転制御）
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)

        // ピンチジェスチャー追加（ズーム）
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)

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

        // カスタム回転制御用
        private var lastPanLocation: CGPoint?
        private var initialCameraDistance: Float = 3.0

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
                print("🎯 Tapped at world coordinates: (\(hitPoint.x), \(hitPoint.y), \(hitPoint.z))")

                // 地球儀ノードを取得（背景球体の子ノードなのでrecursively: trueで検索）
                guard let globeNode = sceneView.scene?.rootNode.childNode(withName: "globe", recursively: true) else {
                    print("⚠️ Globe node not found for tap detection")
                    return
                }

                // ワールド座標を地球儀のローカル座標系に変換（回転を考慮）
                let localPoint = globeNode.convertPosition(hitPoint, from: nil) // nilはワールド座標系から変換
                print("📍 Converted to local coordinates: (\(localPoint.x), \(localPoint.y), \(localPoint.z))")

                // CountryDetectorを使って国を特定（ローカル座標を渡す）
                let country = CountryDetector.shared.detectCountryFromVector(
                    x: localPoint.x,
                    y: localPoint.y,
                    z: localPoint.z
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

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = sceneView,
                  let scene = sceneView.scene,
                  let starfieldNode = scene.rootNode.childNode(withName: "starfield", recursively: false) else {
                return
            }

            let location = gesture.location(in: sceneView)

            switch gesture.state {
            case .began:
                lastPanLocation = location

            case .changed:
                guard let lastLocation = lastPanLocation else { return }

                // 移動量を計算
                let deltaX = Float(location.x - lastLocation.x)
                let deltaY = Float(location.y - lastLocation.y)

                // 感度調整
                let sensitivity: Float = 0.005

                // Y軸回転（横方向のパン）
                let rotationY = simd_quatf(angle: deltaX * sensitivity, axis: simd_float3(0, 1, 0))

                // X軸回転（縦方向のパン）- カメラの現在の右方向を基準に
                let cameraNode = scene.rootNode.childNodes.first { $0.camera != nil }
                let rightVector = cameraNode?.simdWorldRight ?? simd_float3(1, 0, 0)
                let rotationX = simd_quatf(angle: deltaY * sensitivity, axis: rightVector)

                // クォータニオンを合成して背景球体（親ノード）に適用
                // これにより地球儀と背景が一緒に回転する
                let combinedRotation = rotationY * rotationX
                starfieldNode.simdOrientation = combinedRotation * starfieldNode.simdOrientation

                lastPanLocation = location

            case .ended, .cancelled:
                lastPanLocation = nil

            default:
                break
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let sceneView = sceneView,
                  let scene = sceneView.scene,
                  let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) else {
                return
            }

            switch gesture.state {
            case .began:
                initialCameraDistance = cameraNode.position.z

            case .changed:
                // ピンチの拡大縮小率を計算
                let scale = Float(gesture.scale)
                let newDistance = initialCameraDistance / scale

                // ズーム範囲を制限（1.5〜10.0）
                let clampedDistance = max(1.5, min(10.0, newDistance))

                cameraNode.position.z = clampedDistance

            case .ended, .cancelled:
                // 現在の距離を保存
                initialCameraDistance = cameraNode.position.z

            default:
                break
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

            // 球体のマテリアルを更新（地球儀は背景球体の子ノードなのでrecursively: trueで検索）
            if let globeNode = scene.rootNode.childNode(withName: "globe", recursively: true),
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

            // 地球儀ノードを取得（背景球体の子ノードなのでrecursively: trueで検索）
            guard let globeNode = scene.rootNode.childNode(withName: "globe", recursively: true) else {
                print("⚠️ Globe node not found for highlight update")
                return
            }

            // 既存のハイライトを削除（globeNodeの子ノードから削除）
            globeNode.childNodes.filter { $0.name?.starts(with: "highlight_") == true }.forEach { $0.removeFromParentNode() }

            // 新しい国が選択されている場合、ハイライトを追加
            guard let country = country, let geometry = country.geometry else { return }

            for ring in geometry.coordinates {
                guard ring.count >= 2 else { continue }

                var vertices: [SCNVector3] = []

                for point in ring {
                    guard point.count >= 2 else { continue }
                    let lon = point[0]
                    let lat = point[1]

                    // 緯度経度を3D座標に変換（地表より少し外側に配置してはっきり見えるように）
                    let vector = latLonToVector3(lat: lat, lon: lon, radius: 1.002)
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
                    globeNode.addChildNode(lineNode) // 地球儀ノードの子として追加（地球と一緒に回転）
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
