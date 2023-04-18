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
    
    func scanHumanBody(completion: @escaping (URL?, URL?) -> Void) {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("World tracking is not supported on this device.")
            completion(nil, nil)
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .mesh
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = .gravity
        configuration.maximumNumberOfTrackedImages = 0
        arView.session.run(configuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.arView.session.run(configuration)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                self.arView.session.pause()
                
                guard let frame = self.arView.session.currentFrame else { return }
                
                let cameraPosition = simd_make_float3(frame.camera.transform.columns.3)
                
                let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }.filter { anchor in
                    let anchorPosition = simd_make_float3(anchor.transform.columns.3)
                    let distance = self.distanceBetweenPoints(cameraPosition, anchorPosition)
                    return distance <= 2
                }
                
                let objExporter = OBJExporter()
                let plyExporter = PLYExporter()
                
                do {
                    let folderName = "ScannedObjects"
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let folderURL = documentsDirectory.appendingPathComponent(folderName, isDirectory: true)
                    
                    if !FileManager.default.fileExists(atPath: folderURL.path) {
                        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    let modelName = "scannedObject"
                    let objFileURL = folderURL.appendingPathComponent("\(modelName).obj")
                    let plyFileURL = folderURL.appendingPathComponent("\(modelName).ply")
                    
                    try objExporter.export(meshAnchors: meshAnchors, to: objFileURL)
                    try plyExporter.export(meshAnchors: meshAnchors, to: plyFileURL)
                    completion(objFileURL, plyFileURL)
                } catch {
                    print("Failed to save the OBJ and PLY files: \(error)")
                    completion(nil, nil)
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
       
       // Новый метод для экспорта MDLAsset в OBJ (тестовые прогоны)
//       func export(asset: MDLAsset, to fileURL: URL) throws {
//           let objExtension = "obj"
//
//           guard MDLAsset.canExportFileExtension(objExtension) else {
//               throw NSError(domain: "OBJExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "OBJ export is not supported"])
//           }
//
//           try asset.export(to: fileURL)
//    }
}

class PLYExporter {
    func export(meshAnchors: [ARMeshAnchor], to fileURL: URL) throws {
        var header = "ply\n"
        header += "format ascii 1.0\n"
        
        var vertexCount = 0
        var vertices: [String] = []
        
        for anchor in meshAnchors {
            let geometry = anchor.geometry
            let verticesBuffer = geometry.vertices.buffer.contents()
            let vertexCountPerMesh = geometry.vertices.count / geometry.vertices.stride
            
            for vertexIndex in 0..<vertexCountPerMesh {
                let vertexOffset = vertexIndex * geometry.vertices.stride
                let vertex = verticesBuffer.load(fromByteOffset: vertexOffset, as: (Float, Float, Float).self)
                let simdVertex = SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)

                let vertexString = "\(simdVertex.x) \(simdVertex.y) \(simdVertex.z)"
                vertices.append(vertexString)
            }
            
            vertexCount += vertexCountPerMesh
        }
        
        header += "element vertex \(vertexCount)\n"
        header += "property float x\n"
        header += "property float y\n"
        header += "property float z\n"
        header += "end_header\n"
        
        let body = vertices.joined(separator: "\n")
        let plyContent = header + body
        
        guard let plyData = plyContent.data(using: .utf8) else {
            throw NSError(domain: "PLYExporter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create PLY data"])
        }
        
        try plyData.write(to: fileURL)
    }
}
