import Foundation

struct CardScanBounds {
    let left: Double
    let top: Double
    let right: Double
    let bottom: Double

    init(left: Double, top: Double, right: Double, bottom: Double) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }

    init?(from args: Any?) {
        print("[BoundsParser] incoming args:", String(describing: args))
        
        guard
            let dict = args as? [String: Any],
            let boundsDict = dict["bounds"] as? [String: Any],
            let left = boundsDict["left"] as? Double,
            let top = boundsDict["top"] as? Double,
            let right = boundsDict["right"] as? Double,
            let bottom = boundsDict["bottom"] as? Double
        else {
            return nil
        }

        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
}
