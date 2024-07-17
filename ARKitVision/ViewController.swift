import UIKit
import VisionKit
import ARKit

class ViewController: UIViewController, DataScannerViewControllerDelegate, ARSessionDelegate {

    private var dataScannerViewController: DataScannerViewController?
    private var scannedTextLabel: UILabel?
    private var arView: ARSCNView?
    private var selectedText: String?
    private var textNode: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARSession()
    }

    private func setupUI() {
        // Setup AR View
        arView = ARSCNView(frame: view.bounds)
        arView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
    }

    private func setupARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR is not supported on this device.")
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        arView?.session.delegate = self
        arView?.session.run(configuration)
    }

    @objc private func startScanning() {
        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
            print("DataScannerViewController is not supported on this device.")
            return
        }

        let dataScanner = DataScannerViewController(recognizedDataTypes: [.text()], qualityLevel: .fast, recognizesMultipleItems: false, isPinchToZoomEnabled: false)
        dataScanner.delegate = self

        present(dataScanner, animated: true) {
            try? dataScanner.startScanning()
        }

        self.dataScannerViewController = dataScanner
    }

    // MARK: - DataScannerViewControllerDelegate

    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
        case .text(let text):
            selectedText = text.transcript
            scannedTextLabel?.text = "Selected: \(text.transcript)"
            dataScanner.dismiss(animated: true) { [weak self] in
                self?.addTextNode()
            }
        @unknown default:
            break
        }
    }

    // MARK: - AR Tracking

    private func addTextNode() {
        guard let selectedText = selectedText else { return }

        // Create a plane with a gray material
        let plane = SCNPlane(width: 0.1, height: 0.05)
        plane.firstMaterial?.diffuse.contents = UIColor.gray

        // Create a text node
        let textGeometry = SCNText(string: selectedText, extrusionDepth: 1)
        textGeometry.font = UIFont.systemFont(ofSize: 5)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(0, 0, 0.01) // Offset text slightly above the plane

        // Create a parent node
        let parentNode = SCNNode()
        parentNode.geometry = plane
        parentNode.addChildNode(textNode)

        // Position the parent node in front of the camera
        if let cameraTransform = arView?.session.currentFrame?.camera.transform {
            parentNode.simdTransform = matrix_multiply(cameraTransform, matrix_identity_float4x4.translated(by: SIMD3<Float>(0, 0, -0.5)))
        }

        arView?.scene.rootNode.addChildNode(parentNode)
        self.textNode = parentNode
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update the position of the text node to follow the object
        guard let textNode = textNode,
              let cameraTransform = arView?.session.currentFrame?.camera.transform else { return }

        // Adjust the position based on your requirement
        textNode.simdTransform = matrix_multiply(cameraTransform, matrix_identity_float4x4.translated(by: SIMD3<Float>(0, 0, -0.5)))
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
