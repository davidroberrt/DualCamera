import SwiftUI
import AVFoundation

struct MultiCameraPreview: UIViewRepresentable {
    let session: AVCaptureMultiCamSession
    let cameraPosition: AVCaptureDevice.Position
    
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer

        // 🔥 Configura conexão imediatamente
        DispatchQueue.main.async {
            context.coordinator.setupConnection(session: session, position: cameraPosition)
        }

        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Garante que a conexão exista (sem recriar)
        context.coordinator.setupConnection(session: session, position: cameraPosition)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var isConfigured = false
        
        func setupConnection(session: AVCaptureMultiCamSession, position: AVCaptureDevice.Position) {
            guard let previewLayer = previewLayer, !isConfigured else { return }
            
            previewLayer.setSessionWithNoConnection(session)
            
            for input in session.inputs {
                guard let deviceInput = input as? AVCaptureDeviceInput,
                      deviceInput.device.position == position else { continue }
                
                for port in deviceInput.ports where port.mediaType == .video {
                    let connection = AVCaptureConnection(inputPort: port, videoPreviewLayer: previewLayer)
                    
                    if session.canAddConnection(connection) {
                        session.addConnection(connection)
                        isConfigured = true // 🔥 evita duplicação
                        return
                    }
                }
            }
        }
    }
}

// 🔥 View customizada pra ajustar o frame automaticamente
class PreviewView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.frame = bounds }
    }
}
