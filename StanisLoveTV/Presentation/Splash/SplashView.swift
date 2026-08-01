import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(.splashLogo)
                .resizable()
                .scaledToFit()
                .padding()
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    SplashView()
}
#endif
