import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showSuccessMessage: Bool = false
    @State private var navigateToLogin: Bool = false
    @State private var errorMessage: String = "" // For error handling
    
    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .padding()
            
            TextField("Email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: {
                if password == confirmPassword {
                    signUp(email: email, password: password) { success, error in
                        if success {
                            showSuccessMessage = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                navigateToLogin = true
                            }
                        } else if let error = error {
                            errorMessage = error.localizedDescription
                        }
                    }
                } else {
                    errorMessage = "Passwords do not match."
                }
            }) {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 220, height: 60)
                    .background(Color.green)
                    .cornerRadius(15.0)
            }
            
            if showSuccessMessage {
                Text("Successfully signed up!")
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .padding()
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginView()
        }
    }
    
    // Make sure this function exists here
    func signUp(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(false, error)
                return
            }
            completion(true, nil)
        }
    }
}
