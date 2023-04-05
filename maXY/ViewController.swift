import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    var objectScanner: ObjectScanner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = Scene()
        arView.scene.addAnchor(scene)
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
    }
    
    @objc func scanObject(_ sender: UIButton) {
        objectScanner.scanHumanBody { objFileURL in
            if let url = objFileURL {
                print("OBJ file saved at: \(url)")
            } else {
                print("Failed to save the OBJ file")
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
