import ARKit
import MetalKit
import ModelIO

extension ARMeshGeometry {
    func toMDLMesh(device: MTLDevice) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device);
        
        let data = Data.init(bytes: vertices.buffer.contents(), count: vertices.stride * vertices.count);
        let vertexBuffer = allocator.newBuffer(with: data, type: .vertex);
        
        let indexData = Data.init(bytes: faces.buffer.contents(), count: faces.bytesPerIndex * faces.count * faces.indexCountPerPrimitive);
        let indexBuffer = allocator.newBuffer(with: indexData, type: .index);
        
        let submesh = MDLSubmesh(indexBuffer: indexBuffer,
                                 indexCount: faces.count * faces.indexCountPerPrimitive,
                                 indexType: .uInt32,
                                 geometryType: .triangles,
                                 material: nil);
        
        let vertexDescriptor = MDLVertexDescriptor();
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0);
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: vertices.stride);
        
        return MDLMesh(vertexBuffer: vertexBuffer,
                       vertexCount: vertices.count,
                       descriptor: vertexDescriptor,
                       submeshes: [submesh]);
    }
}

