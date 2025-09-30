import UIKit
import Vision
import CoreHaptics
import Flutter

protocol CardScannerDelegate: AnyObject {
    
    func didTapCancel()
    func didTapDone(number: String?, expDate: String?, holder: String?)
    
    func didScanCard(number: String?, expDate: String?, holder: String?)
}

public class CardScannerController : VisionController {
    
    // MARK: - Delegate
    weak var delegate: CardScannerDelegate?
    
    // MRAK: - Ovelay View
    override var overlayViewClass: ScannerOverlayView.Type {
        return CardOverlayView.self
    }

    private let channel: FlutterMethodChannel

    let numberTracker: StringTracker
    let expDateTracker: StringTracker
    let fullNameTracker: StringTracker

    init(configuration: CardScanner.Configuration, channel: FlutterMethodChannel) {
        self.channel = channel
        self.numberTracker = StringTracker(threshold: configuration.cardNumberThreshold)
        self.expDateTracker = StringTracker(threshold: configuration.cardExpiryThreshold)
        self.fullNameTracker = StringTracker(threshold: configuration.cardHolderThreshold)
        super.init(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override var usesLanguageCorrection: Bool {
        return true
    }
    
    override var recognitionLevel: VNRequestTextRecognitionLevel {
        return .accurate
    }
    
    // You can hint here user first/last name
    // To improve card holder detection
    var firstNameSuggestion: String = ""
    var lastNameSuggestion: String = ""

    
    
    var foundNumber : String?
    var foundExpDate : String?
    var foundCardHolder : String?
    
    public override func observationsHandler(observations: [VNRecognizedTextObservation] ) {
        
        var numbers = [StringRecognition]()
        var expDates = [StringRecognition]()
        
        // Create a full transcript to run analysis on.
        var text : String = ""
        var cardHolderCandidate : String = ""
        
        if observationsCount == 20 && (foundNumber == nil) && cameraBrightness < 0 {
            // toggleTorch(on: true)
        }
        
        
        let maximumCandidates = 1
        for observation in observations {
            
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            print("[Text recognition] ", candidate.string)
            
            if foundNumber == nil, let cardNumber = candidate.string.checkCardNumber() {
                let box = observation.boundingBox
                numbers.append((cardNumber, box))
            }
            if let expDate = candidate.string.extractExpDate() {
                let box = boundingBox(of: expDate, in: candidate)
                expDates.append((expDate, box))
            } else if expDates.count > 0 {
                cardHolderCandidate += candidate.string + " "
            }
            
            
            
            text += candidate.string + " "

            highlightBox(observation.boundingBox, color: UIColor.white)
        }
        
        if foundNumber == nil, let cardNumber = text.extractCardNumber() {
            numbers.append((cardNumber, nil))
        }
       
        searchCardNumber(numbers)
        if foundExpDate == nil {
            searchExpDate(expDates)
        }
        
        print("CARD HOLDER CANDIDATE: \(cardHolderCandidate)")
        searchCardHolder(cardHolderCandidate)
        
        shouldStopScanner()
    }
    
    private func searchCardNumber(_ numbers : [StringRecognition]) {
        guard foundNumber == nil else { return }
            
        numberTracker.logFrame(recognitions: numbers)
            
        if let sureNumber = numberTracker.getStableString() {
            foundNumber = sureNumber
            
            
            let cardType = CardValidator().validationType(from: sureNumber)
            let brand = cardType?.group.rawValue ?? ""
            
            numberTracker.reset(string: sureNumber)
        }
    }
    
    private func searchExpDate(_ expDates: [StringRecognition]) {
        guard foundExpDate == nil else { return }
        
        expDateTracker.logFrame(recognitions: expDates)
        
        if let sureExpDate = expDateTracker.getStableString() {
            foundExpDate = sureExpDate
            
            expDateTracker.reset(string: sureExpDate)
        }
    }
    
    private func searchCardHolder(_ text: String) {
        
        guard foundCardHolder == nil else { return }
        
        func trackFullName(_ fullName: StringRecognition) {
            fullNameTracker.logFrame(recognition: fullName)
            
            if let sureFullName = fullNameTracker.getStableString() {
                foundCardHolder = sureFullName
                
                fullNameTracker.reset(string: sureFullName)
            }
        }
        
        if let fullName = text.extractCardHolderSimple() {
            trackFullName((fullName, nil))
        } else if let fullName = text.checkFullName(firstName: firstNameSuggestion, lastName: lastNameSuggestion) {
            trackFullName((fullName, nil))
        }
    }
    
    // MARK: - Scanner Stop
    var observationsCount: Int = 0
    
    private func shouldStopScanner() {
        
        channel.invokeMethod("cardScanning", arguments: [
            "type": "cardScanning",
            "data": [
                "cardNumber": foundNumber ?? numberTracker.getConsensusString(),
                "expiryDate": foundExpDate ?? expDateTracker.getConsensusString(),
                "cardHolder": foundCardHolder ?? fullNameTracker.getConsensusString()
            ]
        ])
        
        if foundNumber != nil && ((foundExpDate != nil && foundCardHolder != nil) || (observationsCount >= self.configuration.observationsCountLimit) ) {
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            stopLiveStream()
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.didScanCard(
                    number: strongSelf.foundNumber ?? strongSelf.numberTracker.getConsensusString(),
                    expDate: strongSelf.foundExpDate ?? strongSelf.expDateTracker.getConsensusString(),
                    holder: strongSelf.foundCardHolder ?? strongSelf.fullNameTracker.getConsensusString()
                )
            }
        }
        
        observationsCount += 1
    }
    
    public override func stopLiveStream() {
        super.stopLiveStream()
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.previewView.layer.sublayers?.removeSubrange(2...)
        }
    }
}
