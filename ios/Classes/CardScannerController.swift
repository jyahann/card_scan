import UIKit
import Vision

protocol CardScannerDelegate: AnyObject {
    func didScanCard(number: String?, expDate: String?, holder: String?)
}

public class CardScannerController: VisionController {
    
    // MARK: - Delegate
    weak var delegate: CardScannerDelegate?
    
    // MARK: - Config
    override var overlayViewClass: ScannerOverlayView.Type {
        return CardOverlayView.self
    }
    §
    override var usesLanguageCorrection: Bool { true }
    override var recognitionLevel: VNRequestTextRecognitionLevel { .accurate }
    
    // Подсказки для имени (опционально)
    var firstNameSuggestion: String = ""
    var lastNameSuggestion: String = ""
    
    // MARK: - Трекеры
    private let numberTracker = StringTracker()
    private let expDateTracker = StringTracker()
    private let fullNameTracker = StringTracker()
    
    // MARK: - Найденные значения
    private var foundNumber: String?
    private var foundExpDate: String?
    private var foundCardHolder: String?
    
    // MARK: - Обработка результатов
    public override func observationsHandler(observations: [VNRecognizedTextObservation]) {
        var numbers = [StringRecognition]()
        var expDates = [StringRecognition]()
        var text = ""
        
        let maximumCandidates = 1
        for observation in observations {
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            let string = candidate.string
            
            if let cardNumber = string.checkCardNumber() {
                numbers.append((cardNumber, observation.boundingBox))
            }
            
            if let expDate = string.extractExpDate() {
                let box = boundingBox(of: expDate, in: candidate)
                expDates.append((expDate, box))
            }
            
            text += string + " "
        }
        
        if let cardNumber = text.extractCardNumber() {
            numbers.append((cardNumber, nil))
        }
        
        searchCardNumber(numbers)
        searchExpDate(expDates)
        searchCardHolder(text)
        
        // Постоянно отправляем данные в делегат, если что-то нашли
        if foundNumber != nil || foundExpDate != nil || foundCardHolder != nil {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didScanCard(
                    number: self.foundNumber,
                    expDate: self.foundExpDate,
                    holder: self.foundCardHolder
                )
            }
        }
    }
    
    // MARK: - Поиск данных
    
    private func searchCardNumber(_ numbers: [StringRecognition]) {
        numberTracker.logFrame(recognitions: numbers)
        if let sureNumber = numberTracker.getStableString() {
            foundNumber = sureNumber
            numberTracker.reset(string: sureNumber)
        }
    }
    
    private func searchExpDate(_ expDates: [StringRecognition]) {
        expDateTracker.logFrame(recognitions: expDates)
        if let sureExpDate = expDateTracker.getStableString() {
            foundExpDate = sureExpDate
            expDateTracker.reset(string: sureExpDate)
        }
    }
    
    private func searchCardHolder(_ text: String) {
        func trackFullName(_ fullName: StringRecognition) {
            fullNameTracker.logFrame(recognition: fullName)
            if let sureFullName = fullNameTracker.getStableString() {
                foundCardHolder = sureFullName
                fullNameTracker.reset(string: sureFullName)
            }
        }
        
        if let fullName = text.extractCardHolder2() {
            trackFullName((fullName, nil))
        } else if let fullName = text.checkFullName(firstName: firstNameSuggestion, lastName: lastNameSuggestion) {
            trackFullName((fullName, nil))
        }
    }
    
    // MARK: - Stop stream (внешний вызов)
    public override func stopLiveStream() {
        super.stopLiveStream()
    }
}
