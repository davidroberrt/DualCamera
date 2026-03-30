import Foundation
import AVFoundation
import SwiftUI
import Photos

class DualCameraViewModel: NSObject, ObservableObject {
    let session = AVCaptureMultiCamSession()
    
    @Published var isRecording = false
    @Published var isFrontPrimary = false
    
    // 🔥 PreviewLayers FIXOS (NÃO recriar nunca)
    let frontPreviewLayer = AVCaptureVideoPreviewLayer()
    let backPreviewLayer = AVCaptureVideoPreviewLayer()
    
    private let frontOutput = AVCaptureMovieFileOutput()
    private let backOutput = AVCaptureMovieFileOutput()

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("❌ MultiCam não suportado")
            return
            
        }
        
        session.beginConfiguration()
        
        // BACK
        guard let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let backInput = try? AVCaptureDeviceInput(device: backDevice),
              session.canAddInput(backInput) else { return }
        
        session.addInput(backInput)
        
        // FRONT
        guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let frontInput = try? AVCaptureDeviceInput(device: frontDevice),
              session.canAddInput(frontInput) else { return }
        
        session.addInput(frontInput)
        
        // 🔥 AUDIO INPUT
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        // 🔥 CONEXÕES (UMA VEZ SÓ)
        for port in backInput.ports where port.mediaType == .video {
            let conn = AVCaptureConnection(inputPort: port, videoPreviewLayer: backPreviewLayer)
            if session.canAddConnection(conn) {
                session.addConnection(conn)
            }
        }
        
        for port in frontInput.ports where port.mediaType == .video {
            let conn = AVCaptureConnection(inputPort: port, videoPreviewLayer: frontPreviewLayer)
            if session.canAddConnection(conn) {
                session.addConnection(conn)
            }
        }
        
        // Outputs
        if session.canAddOutput(backOutput) { session.addOutput(backOutput) }
        if session.canAddOutput(frontOutput) { session.addOutput(frontOutput) }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func toggleRecording() {
        if isRecording {
            frontOutput.stopRecording()
            backOutput.stopRecording()
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let frontURL = docs.appendingPathComponent("front_\(UUID().uuidString).mov")
            let backURL = docs.appendingPathComponent("back_\(UUID().uuidString).mov")
            
            frontOutput.startRecording(to: frontURL, recordingDelegate: self)
            backOutput.startRecording(to: backURL, recordingDelegate: self)
        }
        isRecording.toggle()
    }
}

extension DualCameraViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            }
        }
    }
}
