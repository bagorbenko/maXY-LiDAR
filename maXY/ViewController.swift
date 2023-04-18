import UIKit
import RealityKit
import ARKit
import ReplayKit

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    var objectScanner: ObjectScanner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = Scene()
        arView.scene.addAnchor(scene)
        arView.session.delegate = self
        objectScanner = ObjectScanner(arView: arView, scene: scene)
        
        let scanButton = UIButton(type: .system)
        scanButton.setTitle("Scan Object", for: .normal)
        scanButton.addTarget(self, action: #selector(scanObject(_:)), for: .touchUpInside)
        view.addSubview(scanButton)
        
        // Add constraints
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        config.planeDetection = [.horizontal, .vertical]
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.session.run(config, options: [])
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let arCamera = session.currentFrame?.camera else { return }
            switch arCamera.trackingState {
                case .notAvailable:
                    print("Tracking is not available: \(arCamera.trackingState)")
                case .limited(let reason):
                    print("Tracking is currently limited: \(reason)")
                case .normal:
                    print("tracking is normal: \(arCamera.trackingState)")
            }
    }

    @objc func scanObject(_ sender: UIButton) {
        objectScanner.scanHumanBody { objFileURL, plyFileURL in
            if let objUrl = objFileURL, let plyUrl = plyFileURL {
                print("OBJ file saved at: \(objUrl)")
                print("PLY file saved at: \(plyUrl)")
            } else {
                print("Failed to save the OBJ and PLY files")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
}
