import SwiftUI
import GravityWellKit

struct ContentView: View {
    @StateObject private var viewModel = PhysicsViewModel()
    @State private var showingControls = false
    @State private var selectedGravity: String = "Earth"
    @State private var fps: Double = 0

    let gravityOptions = ["Earth", "Moon", "Mars", "Jupiter", "Sun"]

    var body: some View {
        ZStack {
            // Physics rendering view
            PhysicsView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            // Controls overlay
            VStack {
                // Performance metrics
                HStack {
                    Text("FPS: \(String(format: "%.1f", viewModel.fps))")
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)

                    Text("Objects: \(viewModel.objectCount)")
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)

                    Spacer()

                    Button(action: { showingControls.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                Spacer()

                // Control panel
                if showingControls {
                    VStack(spacing: 15) {
                        // Gravity selector
                        HStack {
                            Text("Gravity:")
                                .foregroundColor(.white)
                            Picker("Gravity", selection: $selectedGravity) {
                                ForEach(gravityOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedGravity) { newValue in
                                viewModel.setGravity(to: newValue)
                            }
                        }

                        // Action buttons
                        HStack(spacing: 20) {
                            Button("Add Shapes") {
                                viewModel.spawnShapes()
                            }
                            .buttonStyle(DemoButtonStyle())

                            Button("Add Gravity Well") {
                                viewModel.addGravityWell()
                            }
                            .buttonStyle(DemoButtonStyle())

                            Button("Clear All") {
                                viewModel.clearAll()
                            }
                            .buttonStyle(DemoButtonStyle(color: .red))
                        }

                        // Physics controls
                        HStack(spacing: 20) {
                            Button(viewModel.isPaused ? "Resume" : "Pause") {
                                viewModel.togglePause()
                            }
                            .buttonStyle(DemoButtonStyle(color: .orange))

                            Button("Reset") {
                                viewModel.reset()
                            }
                            .buttonStyle(DemoButtonStyle(color: .purple))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.setupDemo()
        }
    }
}

struct DemoButtonStyle: ButtonStyle {
    var color: Color = .blue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView()
}