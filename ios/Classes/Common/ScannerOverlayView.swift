import UIKit
import AVFoundation

class ScannerOverlayView: UIView {
    
    private let configuration: CardScanner.Configuration
    
    // MARK: - Init
    required init(configuration: CardScanner.Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        backgroundColor = .clear // ничего не затемняем
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Region of Interest
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    var textOrientation = CGImagePropertyOrientation.up
    
    // MARK: - Coordinate transforms
    var uiRotationTransform = CGAffineTransform.identity
    var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    var roiToGlobalTransform = CGAffineTransform.identity
    var visionToAVFTransform = CGAffineTransform.identity
    
    var bufferAspectRatio: Double = 1920.0 / 1080.0
    
    // MARK: - Device Orientation
    var currentOrientation = UIDeviceOrientation.portrait {
        didSet { updateRegionOfInterest() }
    }
    
    var previewView: PreviewView?
}

extension ScannerOverlayView {
    
    func updateRegionOfInterest() {
        calculateRegionOfInterest()
        setupOrientationAndTransform()
    }
    
    @objc open func calculateRegionOfInterest() {
        let left = configuration.bounds.left
        let top = configuration.bounds.top
        let right = configuration.bounds.right
        let bottom = configuration.bounds.bottom
        
        // так как это проценты, ROI сразу в нормализованных координатах (0..1)
        regionOfInterest = CGRect(
            x: left,
            y: top,
            width: 1.0 - left - right,
            height: 1.0 - top - bottom
        )
        
        print("ROI updated: \(regionOfInterest)")
    }
    
    func setupOrientationAndTransform() {
        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x,
                                                 y: roi.origin.y)
            .scaledBy(x: roi.width, y: roi.height)
        
        switch currentOrientation {
        case .landscapeLeft:
            textOrientation = .up
            uiRotationTransform = .identity
        case .landscapeRight:
            textOrientation = .down
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 1)
                .rotated(by: .pi)
        case .portraitUpsideDown:
            textOrientation = .left
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0)
                .rotated(by: .pi / 2)
        default:
            textOrientation = .right
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 1)
                .rotated(by: -.pi / 2)
        }
        
        visionToAVFTransform = roiToGlobalTransform
            .concatenating(bottomToTopTransform)
            .concatenating(uiRotationTransform)
    }
}
