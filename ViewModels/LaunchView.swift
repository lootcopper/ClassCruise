import SwiftUI

struct LaunchView: View {
    @State private var logoOpacity = 0.0 // Track opacity for animation
    @State private var showInstructions = false // Control visibility of the instructions popup
    @State private var showLogo = true // Control visibility of the logo screen
    @Binding var showMainApp: Bool // Binding to trigger the main app transition

    var body: some View {
        VStack {
            if showLogo {
                VStack {
                    Spacer()

                    Image("ClassCruiseLogo") // Replace with your logo image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 950, height: 950) // Adjust logo size as needed
                        .foregroundColor(.blue) // Customize color
                        .opacity(logoOpacity) // Apply the opacity for animation
                        .onAppear {
                            // Animate opacity from 0 to 1 over 1 second
                            withAnimation(.easeIn(duration: 1)) {
                                logoOpacity = 1.0
                            }
                            // After 3 seconds, show instructions
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showLogo = false
                                showInstructions = true
                            }
                        }

                    Spacer()
                }
                .background(Color.white) // Set background color for the entire screen
                .ignoresSafeArea() // Ensure the background fills the whole screen
            } else {
                EmptyView() // Placeholder for when the logo screen is done
            }
        }
        .sheet(isPresented: $showInstructions) {
            InstructionsView(showInstructions: $showInstructions, showMainApp: $showMainApp)
                .environment(\.colorScheme, .light) // Ensure light mode for instructions screen
        }
    }
}

struct InstructionsView: View {
    @Binding var showInstructions: Bool // Binding to close the popup
    @Binding var showMainApp: Bool // Binding to trigger main app transition

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to ClassCruise!")
                .font(.title2)
                .fontWeight(.bold)
                .padding()

            Text("Here's how to get started:")
                .font(.body)
                .padding(.bottom)

            VStack(alignment: .leading, spacing: 15) {
                Text("1. Create an account or log in.")
                Text("2. To request a carpool: you must fill out your profile information first, including your carpool message. Your requests will not show up unless you complete this step.")
                Text("3. Find other users who need carpooling on the Carpools tab, and connect with them.")
                Text("DISCLAIMER: THIS IS NOT A RIDESHARE APP. IT SHOULD ONLY BE USED TO FIND CARPOOLS/CONNECTIONS.")
            }
            .font(.body)
            .padding()

            Button(action: {
                withAnimation {
                    showInstructions = false // Close the popup
                    showMainApp = true // Transition to the main app
                }
            }) {
                Text("Got it!")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(UIColor.systemBackground)) // Background adapts to light/dark mode
        .cornerRadius(20)
        .shadow(radius: 20)
        .frame(maxWidth: 320) // Adjust popup size for better look
        .padding()
        .transition(.opacity) // Smooth transition when the view appears
    }
}
