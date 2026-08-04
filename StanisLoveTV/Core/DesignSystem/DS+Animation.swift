import SwiftUI

enum DSAnimation {
    static let fast = Animation.easeOut(duration: 0.25)
    static let normal = Animation.easeOut(duration: 0.35)
    static let slow = Animation.easeInOut(duration: 0.6)
}
