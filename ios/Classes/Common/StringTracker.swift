import UIKit

typealias StringRecognition = (text: String, rect: CGRect?)

class StringTracker {
    
    private static let Threshold = 2
    
    var frameIndex: Int64 = 0

    typealias StringObservation = (lastSeen: Int64, count: Int64, box: CGRect?)
    
    // Dictionary of seen strings. Used to get stable recognition before
    // displaying anything.
    var seenStrings = [String: StringObservation]()
    var bestCount = Int64(0)
    var bestString = ""
    var bestBox : CGRect?
    
    func logFrame(string: String) {
        logFrame(strings: [string])
    }
    
    func logFrame(strings: [String]) {
        logFrame(recognitions: strings.map { (text: $0, rect: nil) })
    }
    
    func logFrame(recognition: StringRecognition) {
        logFrame(recognitions: [recognition])
    }

    func logFrame(recognitions: [StringRecognition]) {
        
        for recognition in recognitions {
            if recognition.text.isEmpty { continue }
            
            if seenStrings[recognition.text] == nil {
                seenStrings[recognition.text] = (lastSeen: Int64(0), count: Int64(-1), box: recognition.rect)
            }
            seenStrings[recognition.text]?.lastSeen = frameIndex
            seenStrings[recognition.text]?.count += 1
            seenStrings[recognition.text]?.box = recognition.rect
            print("Seen \(recognition.text) \(seenStrings[recognition.text]?.count ?? 0) times")
        }
    
        var obsoleteStrings = [String]()

        // Go through strings and prune any that have not been seen in while.
        // Also find the (non-pruned) string with the greatest count.
        for (string, obs) in seenStrings {
            // Remove previously seen text after 30 frames (~1s).
            if obs.lastSeen < frameIndex - 30 {
                obsoleteStrings.append(string)
            }
            
            // Find the string with the greatest count.
            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString = string
                bestBox = obs.box
            }
        }
        // Remove old strings.
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }
        
        frameIndex += 1
    }
    
    func getStableString() -> String? {
        // Require the recognizer to see the same string at least "Threshold" times.
        if bestCount >= StringTracker.Threshold {
            return bestString
        } else {
            return nil
        }
    }
    
    func getHighestCountString() -> String? {
        let sortedStrings = seenStrings.sorted { string1, string2 in
            string1.value.count > string2.value.count
        }
        
        return sortedStrings.first?.key
    }
    
    func getStableBox() -> CGRect? {
        // Require the recognizer to see the same string at least "Threshold" times.
        if bestCount >= StringTracker.Threshold {
            return bestBox
        } else {
            return nil
        }
    }
    
    func reset(string: String) {
        seenStrings.removeValue(forKey: string)
        bestCount = 0
        bestString = ""
        bestBox = nil
    }
    
    /// Строит "лучшую" строку:
    /// 1. Находит самую частую длину среди строк.
    /// 2. Для каждой позиции берёт наиболее частый символ.
    func getConsensusString() -> String? {
        guard !seenStrings.isEmpty else { return nil }
        
        // 1. Найдём наиболее частую длину строки
        let lengthCounts = seenStrings.keys.reduce(into: [Int: Int]()) { counts, str in
            counts[str.count, default: 0] += 1
        }
        
        guard let mostCommonLength = lengthCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        // 2. Отфильтруем строки этой длины
        let candidateStrings = seenStrings.keys.filter { $0.count == mostCommonLength }
        guard !candidateStrings.isEmpty else { return nil }
        
        // 3. Для каждой позиции выбираем наиболее частый символ
        var consensusChars: [Character] = []
        
        for i in 0..<mostCommonLength {
            var charFreq: [Character: Int] = [:]
            
            for str in candidateStrings {
                let char = str[str.index(str.startIndex, offsetBy: i)]
                charFreq[char, default: 0] += 1
            }
            
            if let bestChar = charFreq.max(by: { $0.value < $1.value })?.key {
                consensusChars.append(bestChar)
            }
        }
        
        return String(consensusChars)
    }
}
