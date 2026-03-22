import SwiftUI

struct DMGBackgroundView: View {
    let appName: String
    let appsIconPath: String?
    let customBackgroundURL: URL?
    let windowSize: CGSize = CGSize(width: 600, height: 600)
    
    var body: some View {
        ZStack {
            // 1. Background
            if let customBackgroundURL = customBackgroundURL,
               let nsImage = NSImage(contentsOf: customBackgroundURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: windowSize.width, height: windowSize.height)
                    .clipped()
            } else {
                // Mesh-style Professional Gradient
                MeshGradientView()
                    .frame(width: windowSize.width, height: windowSize.height)
            }
            
            // 2. Subtle indigo glow — only show for default background
            if customBackgroundURL == nil {
                Circle()
                    .fill(Color(red: 0.42, green: 0.40, blue: 0.79).opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: 160, y: 140)
            }

            VStack(spacing: 0) {
                // 3. Central Instruction Area (Glass Track)
                // Positioned with a fixed top padding of 100px
                // Total height of track is 200px, so center is exactly at Y=200
                Spacer()
                    .frame(height: 113)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    HStack(spacing: 40) {
                        // App Placeholder (Logo will be placed by Finder at 150, 200)
                        Color.clear
                            .frame(width: 140, height: 140)
                        
                        // Modern Arrow
                        ArrowView()
                            .frame(width: 80, height: 30)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Applications Placement Area (Transparent)
                        Color.clear
                            .frame(width: 140, height: 140)
                    }
                }
                .frame(width: 520, height: 200)
                
                Spacer()
                    .frame(height: 50)
                
                // 4. Instructions
                VStack(spacing: 8) {
                    Text("To install \(appName),")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("drag the icon into the Applications folder")
                        .opacity(0.7)
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Spacer()
                    .frame(height: 70)
            }
        }
        .frame(width: windowSize.width, height: windowSize.height)
    }
}

struct MeshGradientView: View {
    // Notty DA: #0f0f11 (bg) + #232355 (indigo accent)
    static let nottyBg     = Color(red: 0.059, green: 0.059, blue: 0.067) // #0f0f11
    static let nottyIndigo = Color(red: 0.137, green: 0.137, blue: 0.333) // #232355

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Self.nottyIndigo,
                        Self.nottyBg
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                ZStack {
                    RadialGradient(
                        colors: [Self.nottyIndigo.opacity(0.6), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 450
                    )
                    RadialGradient(
                        colors: [Color(red: 0.42, green: 0.40, blue: 0.79).opacity(0.25), .clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 350
                    )
                }
            )
    }
}

struct ArrowView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let midY = geo.size.height / 2
                let width = geo.size.width
                
                // Line
                path.move(to: CGPoint(x: 0, y: midY))
                path.addLine(to: CGPoint(x: width - 15, y: midY))
                
                // Arrow head
                path.move(to: CGPoint(x: width - 20, y: midY - 12))
                path.addLine(to: CGPoint(x: width, y: midY))
                path.addLine(to: CGPoint(x: width - 20, y: midY + 12))
            }
            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
    }
}

// #Preview {
//     DMGBackgroundView(appName: "ExampleApp", appsIconPath: nil, customBackgroundURL: nil)
// }
