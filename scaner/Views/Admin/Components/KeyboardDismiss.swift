import SwiftUI

#if canImport(UIKit)
extension UIApplication {
    /// 关闭当前键盘
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif 