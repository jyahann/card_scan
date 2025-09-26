import SwiftUI

public typealias CardScannerHandler = (_ number: String?, _ expDate: String?, _ holder: String?) -> Void

public struct CardScanner: UIViewControllerRepresentable {

    public struct Configuration {
        let bounds: CardScanBounds
        let drawBoxes: Bool

        init(
            bounds: CardScanBounds,
            drawBoxes: Bool
        ) {
            self.bounds = bounds
            self.drawBoxes = drawBoxes
        }

        public static let `default` = Configuration(
            bounds: CardScanBounds(left: 0.2, top: 0.3, right: 0.2, bottom: 0.3),
            drawBoxes: false
        )
    }
    
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    
    private let firstNameSuggestion: String
    private let lastNameSuggestion: String
    private let configuration: Configuration
    
    // MARK: - Actions
    let onCardScanned: CardScannerHandler
    
    public init(
        firstNameSuggestion: String = "",
        lastNameSuggestion: String = "",
        configuration: Configuration = .default,
        onCardScanned: @escaping CardScannerHandler = { _, _, _ in }
    ) {
        self.firstNameSuggestion = firstNameSuggestion
        self.lastNameSuggestion = lastNameSuggestion
        self.configuration = configuration
        self.onCardScanned = onCardScanned
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
   
    public func makeUIViewController(context: Context) -> CardScannerController {
        let scanner = CardScannerController(configuration: configuration)
        scanner.firstNameSuggestion = firstNameSuggestion
        scanner.lastNameSuggestion = lastNameSuggestion
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: CardScannerController, context: Context) { }
    
    public class Coordinator: NSObject, CardScannerDelegate {

        private let parent: CardScanner
        
        init(_ parent: CardScanner) {
            self.parent = parent
        }
        
        func didTapCancel() {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func didTapDone(number: String?, expDate: String?, holder: String?) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCardScanned(number, expDate, holder)
        }
        
        func didScanCard(number: String?, expDate: String?, holder: String?) { }
    }
}

struct CardScanner_Previews: PreviewProvider {
    static var previews: some View {
        CardScanner()
    }
}
