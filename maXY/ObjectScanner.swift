import UIKit
import ARKit
import RealityKit
import ModelIO
import Metal
import MetalKit
import simd


class ObjectScanner {
    private let arView: ARView
    private let scene: Scene
    
    init(arView: ARView, scene: Scene) {
        self.arView = arView
        self.scene = scene
    }
    func distanceBetweenPoints(_ point1: simd_float3, _ point2: simd_float3) -> Float {
        let deltaX = point2.x - point1.x
        let deltaY = point2.y - point1.y
        let deltaZ = point2.z - point1.z
        return sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
    }
    
    
    func scanHumanBody(completion: @escaping (URL?) -> Void) {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("World tracking is not supported on this device.")
            completion(nil)
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .mesh
        arView.session.run(configuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.arView.session.run(configuration)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                self.arView.session.pause()
                
                guard let frame = self.arView.session.currentFrame else { return }
                
                let cameraPosition = simd_make_float3(frame.camera.transform.columns.3)
                
                
                let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }.filter { anchor in
                    let anchorPosition = simd_make_float3(anchor.transform.columns.3)
                    let distance = self.distanceBetweenPoints(cameraPosition, anchorPosition)
                    return distance <= 3.0
                }
                
                let objExporter = OBJExporter()
                
                do {
                    let folderName = "OBJ"
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let folderURL = documentsDirectory.appendingPathComponent(folderName, isDirectory: true)
                    
                    if !FileManager.default.fileExists(atPath: folderURL.path) {
                        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    let modelName = "scannedHumanBody"
                    let objFileURL = folderURL.appendingPathComponent("\(modelName).obj")
                    
                    try objExporter.export(meshAnchors: meshAnchors, to: objFileURL)
                    completion(objFileURL)
                } catch {
                    print("Failed to save the OBJ file: \(error)")
                    completion(nil)
                }
            }
        }
    }
}
    
    
    class OBJExporter {
        func export(meshAnchors: [ARMeshAnchor], to fileURL: URL) throws {
            let asset = MDLAsset()
            
            let device = MTLCreateSystemDefaultDevice()!
            
            for meshAnchor in meshAnchors {
                let mdlMesh = meshAnchor.geometry.toMDLMesh(device: device)
                asset.add(mdlMesh)
            }
            
            let objExtension = "obj"
            
            guard MDLAsset.canExportFileExtension(objExtension) else {
                throw NSError(domain: "OBJExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "OBJ export is not supported"])
            }
            
            try asset.export(to: fileURL)
        }
        
        // Новый метод для экспорта MDLAsset в OBJ
        func export(asset: MDLAsset, to fileURL: URL) throws {
            let objExtension = "obj"
            
            guard MDLAsset.canExportFileExtension(objExtension) else {
                throw NSError(domain: "OBJExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "OBJ export is not supported"])
            }
            
            try asset.export(to: fileURL)
        }
    }





