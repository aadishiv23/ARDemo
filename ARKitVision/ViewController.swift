//import UIKit
//import VisionKit
//import ARKit
//
//class ViewController: UIViewController, DataScannerViewControllerDelegate, ARSessionDelegate, ARSCNViewDelegate {
//
//    private var dataScannerViewController: DataScannerViewController?
//    private var scannedTextLabel: UILabel?
//    private var arView: ARSCNView?
//    private var selectedText: String?
//    private var textNode: SCNNode?
//    private var selectedTextPosition: CGPoint?
//    private var debugLabel: UILabel?
//    private var textAnchor: ARAnchor?
//    private var visionRequests = [VNRequest]()
//    private var currentBuffer: CVPixelBuffer?
//    private var isProcessingFrame = false
//    private var frameCounter = 0
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupARSession()
//        setupVision()
//    }
//
//    private func setupUI() {
//        // Setup AR View
//        arView = ARSCNView(frame: view.bounds)
//        arView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        arView?.showsStatistics = true
//        arView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
//        arView?.delegate = self
//        view.addSubview(arView!)
//
//        // Setup Scanned Text Label
//        scannedTextLabel = UILabel()
//        scannedTextLabel?.translatesAutoresizingMaskIntoConstraints = false
//        scannedTextLabel?.textAlignment = .center
//        scannedTextLabel?.backgroundColor = .black.withAlphaComponent(0.7)
//        scannedTextLabel?.textColor = .white
//        scannedTextLabel?.numberOfLines = 0
//        view.addSubview(scannedTextLabel!)
//
//        NSLayoutConstraint.activate([
//            scannedTextLabel!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            scannedTextLabel!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            scannedTextLabel!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
//        ])
//
//        // Setup Scan Button
//        let scanButton = UIButton(type: .system)
//        scanButton.setTitle("Scan Text", for: .normal)
//        scanButton.addTarget(self, action: #selector(startScanning), for: .touchUpInside)
//        scanButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scanButton)
//
//        NSLayoutConstraint.activate([
//            scanButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
//
//        // Setup Debug Label
//        debugLabel = UILabel()
//        debugLabel?.translatesAutoresizingMaskIntoConstraints = false
//        debugLabel?.textAlignment = .left
//        debugLabel?.backgroundColor = .black.withAlphaComponent(0.7)
//        debugLabel?.textColor = .white
//        debugLabel?.numberOfLines = 0
//        view.addSubview(debugLabel!)
//
//        NSLayoutConstraint.activate([
//            debugLabel!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            debugLabel!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            debugLabel!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60)
//        ])
//    }
//
//    private func setupARSession() {
//        guard ARWorldTrackingConfiguration.isSupported else {
//            debugLabel?.text = "AR is not supported on this device."
//            return
//        }
//
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = [.horizontal, .vertical]
//        arView?.session.delegate = self
//        arView?.session.run(configuration)
//        debugLabel?.text = "AR session started"
//    }
//
//    private func setupVision() {
//        let textRequest = VNRecognizeTextRequest(completionHandler: detectTextHandler)
//        textRequest.recognitionLevel = .accurate
//        visionRequests = [textRequest]
//    }
//
//    @objc private func startScanning() {
//        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
//            debugLabel?.text = "DataScannerViewController is not supported on this device."
//            return
//        }
//
//        let dataScanner = DataScannerViewController(recognizedDataTypes: [.text()], qualityLevel: .fast, recognizesMultipleItems: true, isPinchToZoomEnabled: true, isHighlightingEnabled: true)
//        dataScanner.delegate = self
//
//        present(dataScanner, animated: true) {
//            try? dataScanner.startScanning()
//        }
//
//        self.dataScannerViewController = dataScanner
//        debugLabel?.text = "Scanning started"
//    }
//
//    // MARK: - DataScannerViewControllerDelegate
//
//    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
//        switch item {
//        case .text(let text):
//            selectedText = text.transcript
//            scannedTextLabel?.text = "Selected: \(text.transcript)"
//            selectedTextPosition = dataScanner.view.convert(text.bounds.bottomLeft, to: arView)
//            debugLabel?.text = "Text selected: \(text.transcript)\nPosition: \(selectedTextPosition ?? .zero)"
//            dataScanner.dismiss(animated: true) { [weak self] in
//                self?.addTextNode()
//            }
//        @unknown default:
//            break
//        }
//    }
//
//    // MARK: - AR Tracking
//
//    private func addTextNode() {
//        guard let selectedText = selectedText, let arView = arView, let position = selectedTextPosition else {
//            debugLabel?.text = "Failed to add text node: missing data"
//            return
//        }
//
//        removeExistingTextNode()
//
//        // Perform a ray cast to find a plane or feature point
//        if let hitTestResult = arView.raycastQuery(from: position, allowing: .estimatedPlane, alignment: .any),
//           let result = arView.session.raycast(hitTestResult).first {
//
//            // Create a plane with a gray material
//            let plane = SCNPlane(width: 0.2, height: 0.1)  // Increased size for visibility
//            plane.firstMaterial?.diffuse.contents = UIColor.gray
//
//            // Create a text node
//            let textGeometry = SCNText(string: selectedText, extrusionDepth: 1)
//            textGeometry.font = UIFont.systemFont(ofSize: 10)  // Increased size for visibility
//            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
//            let textNode = SCNNode(geometry: textGeometry)
//            textNode.scale = SCNVector3(0.01, 0.01, 0.01)  // Scale down the text
//            textNode.position = SCNVector3(0, 0, 0.01) // Offset text slightly above the plane
//
//            // Create a parent node
//            let parentNode = SCNNode()
//            parentNode.geometry = plane
//            parentNode.addChildNode(textNode)
//
//            // Position the parent node
//            parentNode.simdWorldTransform = result.worldTransform
//
//            // Create an AR anchor
//            let anchor = ARAnchor(transform: result.worldTransform)
//            arView.session.add(anchor: anchor)
//            arView.scene.rootNode.addChildNode(parentNode)
//
//            self.textNode = parentNode
//            self.textAnchor = anchor
//            debugLabel?.text = "Text node added at position: \(result.worldTransform.columns.3.x), \(result.worldTransform.columns.3.y), \(result.worldTransform.columns.3.z)"
//        } else {
//            debugLabel?.text = "Failed to add text node: couldn't find surface"
//        }
//    }
//
//    private func removeExistingTextNode() {
//        if let anchor = textAnchor {
//            arView?.session.remove(anchor: anchor)
//        }
//        textNode?.removeFromParentNode()
//        textNode = nil
//        textAnchor = nil
//    }
//
//    // MARK: - ARSessionDelegate
//
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        guard !isProcessingFrame, case .normal = frame.camera.trackingState else {
//            return
//        }
//
//        // Throttle Vision requests by only processing every nth frame
//        frameCounter += 1
//        if frameCounter % 10 != 0 { // Adjust this value to control the frequency of Vision requests
//            return
//        }
//
//        isProcessingFrame = true
//        currentBuffer = frame.capturedImage
//        classifyCurrentImage()
//    }
//
//    private func classifyCurrentImage() {
//        guard let buffer = currentBuffer else { return }
//        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
//
//        let requestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation)
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try requestHandler.perform(self.visionRequests)
//            } catch {
//                DispatchQueue.main.async {
//                    self.debugLabel?.text = "Vision request failed: \(error.localizedDescription)"
//                }
//            }
//            DispatchQueue.main.async {
//                self.isProcessingFrame = false
//            }
//        }
//    }
//
//    private func detectTextHandler(request: VNRequest, error: Error?) {
//        guard let observations = request.results as? [VNRecognizedTextObservation], let arView = arView, let selectedText = selectedText else { return }
//
//        for observation in observations {
//            guard let topCandidate = observation.topCandidates(1).first else { continue }
//
//            if topCandidate.string == selectedText {
//                let boundingBox = observation.boundingBox
//
//                DispatchQueue.main.async {
//                    self.updateTextNodePosition(with: boundingBox)
//                }
//                break
//            }
//        }
//    }
//
//    private func updateTextNodePosition(with boundingBox: CGRect) {
//        guard let arView = arView else { return }
//
//        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
//        let convertedCenter = arView.convert(center, to: arView)
//
//        // Perform a ray cast to find a plane or feature point
//        if let hitTestResult = arView.raycastQuery(from: convertedCenter, allowing: .estimatedPlane, alignment: .any),
//           let result = arView.session.raycast(hitTestResult).first {
//            textNode?.simdWorldTransform = result.worldTransform
//        }
//    }
//
//    // MARK: - ARSCNViewDelegate
//
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        guard anchor == textAnchor else { return nil }
//        return textNode
//    }
//}
//
//extension CGRect {
//    var center: CGPoint {
//        return CGPoint(x: midX, y: midY)
//    }
//}
//
//extension matrix_float4x4 {
//    func translated(by translation: SIMD3<Float>) -> matrix_float4x4 {
//        var result = self
//        result.columns.3.x += translation.x
//        result.columns.3.y += translation.y
//        result.columns.3.z += translation.z
//        return result
//    }
//}
//
//
//
//import UIKit
//import VisionKit
//import ARKit
//
//class ViewController: UIViewController, DataScannerViewControllerDelegate, ARSessionDelegate {
//
//    private var dataScannerViewController: DataScannerViewController?
//    private var scannedTextLabel: UILabel?
//    private var arView: ARSCNView?
//    private var selectedText: String?
//    private var textNode: SCNNode?
//    private var selectedTextPosition: CGPoint?
//    private var debugLabel: UILabel?
//    private var textAnchor: ARAnchor?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupARSession()
//    }
//
//    private func setupUI() {
//        // Setup AR View
//        arView = ARSCNView(frame: view.bounds)
//        arView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        arView?.showsStatistics = true
//        arView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
//        view.addSubview(arView!)
//
//        // Setup Scanned Text Label
//        scannedTextLabel = UILabel()
//        scannedTextLabel?.translatesAutoresizingMaskIntoConstraints = false
//        scannedTextLabel?.textAlignment = .center
//        scannedTextLabel?.backgroundColor = .black.withAlphaComponent(0.7)
//        scannedTextLabel?.textColor = .white
//        scannedTextLabel?.numberOfLines = 0
//        view.addSubview(scannedTextLabel!)
//
//        NSLayoutConstraint.activate([
//            scannedTextLabel!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            scannedTextLabel!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            scannedTextLabel!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
//        ])
//
//        // Setup Scan Button
//        let scanButton = UIButton(type: .system)
//        scanButton.setTitle("Scan Text", for: .normal)
//        scanButton.addTarget(self, action: #selector(startScanning), for: .touchUpInside)
//        scanButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scanButton)
//
//        NSLayoutConstraint.activate([
//            scanButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
//
//        // Setup Debug Label
//        debugLabel = UILabel()
//        debugLabel?.translatesAutoresizingMaskIntoConstraints = false
//        debugLabel?.textAlignment = .left
//        debugLabel?.backgroundColor = .black.withAlphaComponent(0.7)
//        debugLabel?.textColor = .white
//        debugLabel?.numberOfLines = 0
//        view.addSubview(debugLabel!)
//
//        NSLayoutConstraint.activate([
//            debugLabel!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            debugLabel!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            debugLabel!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60)
//        ])
//    }
//
//    private func setupARSession() {
//        guard ARWorldTrackingConfiguration.isSupported else {
//            debugLabel?.text = "AR is not supported on this device."
//            return
//        }
//
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = [.horizontal, .vertical]
//        arView?.session.delegate = self
//        arView?.session.run(configuration)
//        debugLabel?.text = "AR session started"
//    }
//
//    @objc private func startScanning() {
//        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
//            debugLabel?.text = "DataScannerViewController is not supported on this device."
//            return
//        }
//
//        let dataScanner = DataScannerViewController(recognizedDataTypes: [.text()], qualityLevel: .fast, recognizesMultipleItems: true, isPinchToZoomEnabled: true, isHighlightingEnabled: true)
//        dataScanner.delegate = self
//
//        present(dataScanner, animated: true) {
//            try? dataScanner.startScanning()
//        }
//
//        self.dataScannerViewController = dataScanner
//        debugLabel?.text = "Scanning started"
//    }
//
//    // MARK: - DataScannerViewControllerDelegate
//
//    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
//        switch item {
//        case .text(let text):
//            selectedText = text.transcript
//            scannedTextLabel?.text = "Selected: \(text.transcript)"
//            selectedTextPosition = dataScanner.view.convert(text.bounds.bottomLeft, to: arView)
//            debugLabel?.text = "Text selected: \(text.transcript)\nPosition: \(selectedTextPosition ?? .zero)"
//            dataScanner.dismiss(animated: true) { [weak self] in
//                self?.addTextNode()
//            }
//        @unknown default:
//            break
//        }
//    }
//
//    // MARK: - AR Tracking
//
//    private func addTextNode() {
//        guard let selectedText = selectedText, let arView = arView, let position = selectedTextPosition else {
//            debugLabel?.text = "Failed to add text node: missing data"
//            return
//        }
//
//        removeExistingTextNode()
//
//        // Perform a ray cast to find a plane or feature point
//        if let hitTestResult = arView.raycastQuery(from: position, allowing: .estimatedPlane, alignment: .any),
//           let result = arView.session.raycast(hitTestResult).first {
//
//            // Create a plane with a gray material
//            let plane = SCNPlane(width: 0.2, height: 0.1)  // Increased size for visibility
//            plane.firstMaterial?.diffuse.contents = UIColor.gray
//
//            // Create a text node
//            let textGeometry = SCNText(string: selectedText, extrusionDepth: 1)
//            textGeometry.font = UIFont.systemFont(ofSize: 10)  // Increased size for visibility
//            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
//            let textNode = SCNNode(geometry: textGeometry)
//            textNode.scale = SCNVector3(0.01, 0.01, 0.01)  // Scale down the text
//            textNode.position = SCNVector3(0, 0, 0.01) // Offset text slightly above the plane
//
//            // Create a parent node
//            let parentNode = SCNNode()
//            parentNode.geometry = plane
//            parentNode.addChildNode(textNode)
//
//            // Position the parent node
//            parentNode.simdWorldTransform = result.worldTransform
//
//            // Create an AR anchor
//            let anchor = ARAnchor(transform: result.worldTransform)
//            arView.session.add(anchor: anchor)
//            arView.scene.rootNode.addChildNode(parentNode)
//
//            self.textNode = parentNode
//            self.textAnchor = anchor
//            debugLabel?.text = "Text node added at position: \(result.worldTransform.columns.3.x), \(result.worldTransform.columns.3.y), \(result.worldTransform.columns.3.z)"
//        } else {
//            debugLabel?.text = "Failed to add text node: couldn't find surface"
//        }
//    }
//
//    private func removeExistingTextNode() {
//        if let anchor = textAnchor {
//            arView?.session.remove(anchor: anchor)
//        }
//        textNode?.removeFromParentNode()
//        textNode = nil
//        textAnchor = nil
//    }
//
//    // MARK: - ARSessionDelegate
//
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        // No need to manually update the text node position as it is now anchored to the real-world position
//    }
//
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        debugLabel?.text = "AR session failed: \(error.localizedDescription)"
//    }
//
//    func sessionWasInterrupted(_ session: ARSession) {
//        debugLabel?.text = "AR session was interrupted"
//    }
//
//    func sessionInterruptionEnded(_ session: ARSession) {
//        debugLabel?.text = "AR session interruption ended"
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        guard anchor == textAnchor else { return nil }
//        return textNode
//    }
//}
//
//extension CGRect {
//    var center: CGPoint {
//        return CGPoint(x: midX, y: midY)
//    }
//}
//
//extension matrix_float4x4 {
//    func translated(by translation: SIMD3<Float>) -> matrix_float4x4 {
//        var result = self
//        result.columns.3.x += translation.x
//        result.columns.3.y += translation.y
//        result.columns.3.z += translation.z
//        return result
//    }
//}

import UIKit
import VisionKit
import ARKit

class ViewController: UIViewController, DataScannerViewControllerDelegate, ARSessionDelegate {

    private var dataScannerViewController: DataScannerViewController?
    private var scannedTextLabel: UILabel?
    private var arView: ARSCNView?
    private var selectedText: String?
    private var textNode: SCNNode?
    private var selectedTextPosition: CGPoint?
    private var debugLabel: UILabel?
    private var previousPosition: simd_float4x4?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARSession()
    }

    private func setupUI() {
        // Setup AR View
        arView = ARSCNView(frame: view.bounds)
        arView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView?.showsStatistics = true
        arView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        view.addSubview(arView!)

        // Setup Scanned Text Label
        scannedTextLabel = UILabel()
        scannedTextLabel?.translatesAutoresizingMaskIntoConstraints = false
        scannedTextLabel?.textAlignment = .center
        scannedTextLabel?.backgroundColor = .black.withAlphaComponent(0.7)
        scannedTextLabel?.textColor = .white
        scannedTextLabel?.numberOfLines = 0
        view.addSubview(scannedTextLabel!)

        NSLayoutConstraint.activate([
            scannedTextLabel!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scannedTextLabel!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scannedTextLabel!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // Setup Scan Button
        let scanButton = UIButton(type: .system)
        scanButton.setTitle("Scan Text", for: .normal)
        scanButton.addTarget(self, action: #selector(startScanning), for: .touchUpInside)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanButton)

        NSLayoutConstraint.activate([
            scanButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Setup Debug Label
        debugLabel = UILabel()
        debugLabel?.translatesAutoresizingMaskIntoConstraints = false
        debugLabel?.textAlignment = .left
        debugLabel?.backgroundColor = .black.withAlphaComponent(0.7)
        debugLabel?.textColor = .white
        debugLabel?.numberOfLines = 0
        view.addSubview(debugLabel!)

        NSLayoutConstraint.activate([
            debugLabel!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugLabel!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugLabel!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60)
        ])
    }

    private func setupARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            debugLabel?.text = "AR is not supported on this device."
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView?.session.delegate = self
        arView?.session.run(configuration)
        debugLabel?.text = "AR session started"
    }

    @objc private func startScanning() {
        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
            debugLabel?.text = "DataScannerViewController is not supported on this device."
            return
        }

        let dataScanner = DataScannerViewController(recognizedDataTypes: [.text()], qualityLevel: .fast, recognizesMultipleItems: true, isPinchToZoomEnabled: true, isHighlightingEnabled: true)
        dataScanner.delegate = self

        present(dataScanner, animated: true) {
            try? dataScanner.startScanning()
        }

        self.dataScannerViewController = dataScanner
        debugLabel?.text = "Scanning started"
    }

    // MARK: - DataScannerViewControllerDelegate

    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
        case .text(let text):
            selectedText = text.transcript
            scannedTextLabel?.text = "Selected: \(text.transcript)"
            selectedTextPosition = dataScanner.view.convert(text.bounds.bottomLeft, to: arView)
            debugLabel?.text = "Text selected: \(text.transcript)\nPosition: \(selectedTextPosition ?? .zero)"
            dataScanner.dismiss(animated: true) { [weak self] in
                self?.addTextNode()
            }
        @unknown default:
            break
        }
    }

    // MARK: - AR Tracking

    private func addTextNode() {
        guard let selectedText = selectedText, let arView = arView, let position = selectedTextPosition else {
            debugLabel?.text = "Failed to add text node: missing data"
            return
        }

        removeExistingTextNode()

        // Perform a ray cast to find a plane or feature point
        if let hitTestResult = arView.raycastQuery(from: position, allowing: .estimatedPlane, alignment: .any),
           let result = arView.session.raycast(hitTestResult).first {

            // Create a plane with a gray material
            let plane = SCNPlane(width: 0.2, height: 0.1)  // Increased size for visibility
            plane.firstMaterial?.diffuse.contents = UIColor.gray

            // Create a text node
            let textGeometry = SCNText(string: selectedText, extrusionDepth: 1)
            textGeometry.font = UIFont.systemFont(ofSize: 5)  // Increased size for visibility
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3(0.01, 0.01, 0.01)  // Scale down the text
            textNode.position = SCNVector3(0, 0, 0) // Offset text slightly above the plane

            // Add billboard constraint to make text face the camera
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.X, .Y]
            textNode.constraints = [billboardConstraint]

            //textNode.position = SCNVector3(0, 0, -1)

            // Create a parent node
            let parentNode = SCNNode()
            parentNode.constraints = [billboardConstraint]
            parentNode.geometry = plane
            parentNode.addChildNode(textNode)

            // Position the parent node
            parentNode.simdWorldTransform = result.worldTransform

            // Add the node to the scene
            arView.scene.rootNode.addChildNode(parentNode)

            self.textNode = parentNode
            previousPosition = result.worldTransform
            debugLabel?.text = "Text node added at position: \(result.worldTransform.columns.3.x), \(result.worldTransform.columns.3.y), \(result.worldTransform.columns.3.z)"
        } else {
            debugLabel?.text = "Failed to add text node: couldn't find surface"
        }
    }

    private func removeExistingTextNode() {
        textNode?.removeFromParentNode()
        textNode = nil
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let textNode = textNode, let position = selectedTextPosition, let previousPosition = previousPosition else { return }

        // Perform a new ray cast for each frame
        if let hitTestResult = arView?.raycastQuery(from: position, allowing: .estimatedPlane, alignment: .any),
           let result = session.raycast(hitTestResult).first {

            // Apply a low-pass filter to stabilize the position
            let alpha: Float = 0.5
            textNode.simdWorldTransform = previousPosition.translated(by: SIMD3<Float>(
                x: (result.worldTransform.columns.3.x - previousPosition.columns.3.x) * alpha,
                y: (result.worldTransform.columns.3.y - previousPosition.columns.3.y) * alpha,
                z: (result.worldTransform.columns.3.z - previousPosition.columns.3.z) * alpha
            ))

            self.previousPosition = textNode.simdWorldTransform
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        debugLabel?.text = "AR session failed: \(error.localizedDescription)"
    }

    func sessionWasInterrupted(_ session: ARSession) {
        debugLabel?.text = "AR session was interrupted"
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        debugLabel?.text = "AR session interruption ended"
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension matrix_float4x4 {
    func translated(by translation: SIMD3<Float>) -> matrix_float4x4 {
        var result = self
        result.columns.3.x += translation.x
        result.columns.3.y += translation.y
        result.columns.3.z += translation.z
        return result
    }
}
