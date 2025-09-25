import SwiftUI

public typealias CardScannerHandler = (_ number: String?, _ expDate: String?, _ holder: String?) -> Void

public struct CardScanner: UIViewControllerRepresentable {

    public struct Configuration {
        // Основные коэффициенты
        let bounds: CardScanBounds

        init(
            bounds: CardScanBounds,
        ) {
            self.bounds = bounds
        }

        // Дефолтная конфигурация
        public static let `default` = Configuration(
            bounds: CardScanBounds(
                left: 0.15, top: 0.35, right: 0.15, bottom: 0.35
            )
        )
    }
    
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    
    private let configuration: Configuration
    
    // MARK: - Actions
    let onCardScanned: CardScannerHandler
    
    public init(
        configuration: Configuration = .default,
        onCardScanned: @escaping CardScannerHandler = { _, _, _ in }
    ) {
        self.configuration = configuration
        self.onCardScanned = onCardScanned
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
   
    public func makeUIViewController(context: Context) -> CardScannerController {
        let scanner = CardScannerController(configuration: configuration)
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: CardScannerController, context: Context) { }
    
    public class Coordinator: NSObject, CardScannerDelegate {

        private let parent: CardScanner
        
        init(_ parent: CardScanner) {
            self.parent = parent
        }
        
        func didScanCard(number: String?, expDate: String?, holder: String?) { }
    }
}
