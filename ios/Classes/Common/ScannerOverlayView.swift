import UIKit
import AVFoundation

class ScannerOverlayView: UIView {
    
    private let configuration: CardScanner.Configuration
    
    // MARK: - Init
    required init(configuration: CardScanner.Configuration) {
        self.configuration = configuration

        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        layer.mask = maskLayer
    }
    
    // MARK: - Mask Layer
    lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.fillRule = .evenOdd
        return layer
    }()
    
    // Region of video data output buffer that recognition should be run on.
    // Gets recalculated once the bounds of the preview layer are known.
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    // Orientation of text to search for in the region of interest.
    var textOrientation = CGImagePropertyOrientation.up
    
    // MARK: - Coordinate transforms
    var uiRotationTransform = CGAffineTransform.identity
    // Transform bottom-left coordinates to top-left.
    var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    // Transform coordinates in ROI to global coordinates (still normalized).
    var roiToGlobalTransform = CGAffineTransform.identity
    // Vision -> AVF coordinate transform.
    var visionToAVFTransform = CGAffineTransform.identity
    
    var bufferAspectRatio: Double = 1_920.0 / 1_080.0
    
    // MARK: - Device Orientation
    // Device orientation.Updated whenever the orientation changes
    // to a different supported orientation.
    var currentOrientation = UIDeviceOrientation.portrait {
        didSet {
            // update ROI if orientation changes
            updateRegionOfInterest()
        }
    }
    
    // MARK: - Preview View
    var previewView: PreviewView?
}

extension ScannerOverlayView {
    
    func updateRegionOfInterest() {
    
        // calculate new ROI
        calculateRegionOfInterest()
        
        // ROI changed, update transform.
        setupOrientationAndTransform()
        
        // Update the cutout to match the new ROI.
        // DispatchQueue.main.async { [weak self] in
        //     // Wait for the next run cycle before updating the cutout. This
        //     // ensures that the preview layer already has its new orientation.
        //     self?.updateCutout()
        // }
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
        // Recalculate the affine transform between Vision coordinates and AVF coordinates.
        
        // Compensate for region of interest.
        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x, y: roi.origin.y).scaledBy(x: roi.width, y: roi.height)
        
        // Compensate for orientation (buffers always come in the same orientation).
        switch currentOrientation {
        case .landscapeLeft:
            textOrientation = CGImagePropertyOrientation.up
            uiRotationTransform = CGAffineTransform.identity
        case .landscapeRight:
            textOrientation = CGImagePropertyOrientation.down
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 1).rotated(by: CGFloat.pi)
        case .portraitUpsideDown:
            textOrientation = CGImagePropertyOrientation.left
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0).rotated(by: CGFloat.pi / 2)
        default: // We default everything else to .portraitUp
            textOrientation = CGImagePropertyOrientation.right
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -CGFloat.pi / 2)
        }
        
        // Full Vision ROI to AVF transform.
        visionToAVFTransform = roiToGlobalTransform.concatenating(bottomToTopTransform).concatenating(uiRotationTransform)
    }
    
    
    @objc open func addOverlays(_ cutout: CGRect) {
        
        //addRoundedRectangle(around: cutout)
        //addWatermark()
        
        // override to add additional layers on overlay
    }
}