import SwiftUI
import UIKit

struct AnimatedBackground: View {
    @State var animation = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                firstImage(geometry)
                image(geometry)
                image(geometry)
                image(geometry)
                VisualEffect(effect: UIBlurEffect(style: .light))
                VisualEffect(effect: UIBlurEffect(style: .light))
                VisualEffect(effect: UIBlurEffect(style: .dark))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(Animation.linear(duration: 50).repeatForever()) {
                animation.toggle()
            }
        }
    }

    func image(_ geometry: GeometryProxy) -> some View {
        Image("image")
            .resizable()
            .frame(
                width: randomFrame(geometry.size.width),
                height: randomFrame(geometry.size.width)
            )
            .scaleEffect(randomCGFloat(in: 1...2.5))
            .opacity(0.5)
            .rotationEffect(.degrees(randomDouble(in: -360...360)), anchor: .center)
            .offset(x: randomCGFloat(in: -300...300), y: randomCGFloat(in: -300...300))
            .blendMode(.lighten)
            .saturation(randomDouble(in: 0.4...1.4))
            .contrast(2)
    }

    func firstImage(_ geometry: GeometryProxy) -> some View {
        Image("image")
            .resizable()
            .brightness(-0.5)
            .rotationEffect(.degrees(randomDouble(in: -360...360)), anchor: .center)
            .frame(width: geometry.size.height*2, height: geometry.size.height*2)
    }

    func randomFrame(_ base: CGFloat) -> CGFloat {
        let randomNumber = animation ? CGFloat.random(in: -100...300) : CGFloat.random(in: -100...300)
        let frame = base + randomNumber
        return frame
    }

    func randomCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let randomNumber = animation ? CGFloat.random(in: range) : CGFloat.random(in: range)
        return randomNumber
    }

    func randomDouble(in range: ClosedRange<Double>) -> Double {
        let randomNumber = animation ? Double.random(in: range) : Double.random(in: range)
        return randomNumber
    }
}

struct AnimatedBackground_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedBackground()
    }
}
