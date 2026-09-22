import SwiftUI

public struct ConfettiParticle: Identifiable {
    public let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var opacity: Double
}

public struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    private let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .green, .mint]
    
    public init() {}
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .position(x: p.x, y: p.y)
                        .rotationEffect(.degrees(p.rotation))
                        .opacity(p.opacity)
                }
            }
            .onAppear {
                spawnParticles(in: proxy.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func spawnParticles(in size: CGSize) {
        var newParticles: [ConfettiParticle] = []
        for _ in 0..<75 {
            let p = ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? .blue,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            newParticles.append(p)
        }
        particles = newParticles
        
        withAnimation(.easeOut(duration: 2.8)) {
            for index in particles.indices {
                particles[index].y = CGFloat.random(in: size.height * 0.4...size.height + 50)
                particles[index].x += CGFloat.random(in: -100...100)
                particles[index].rotation += Double.random(in: 180...720)
                particles[index].opacity = 0.0
            }
        }
    }
}
