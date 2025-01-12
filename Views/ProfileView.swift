import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var phoneNumber: String = ""
    @State private var userName: String = ""
    @State private var carpoolMessage: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var isImagePickerPresented = false

    var body: some View {
        VStack {
            VStack(spacing: 10) {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text("Tap to Add Photo")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                        .onTapGesture {
                            isImagePickerPresented = true
                        }
                }
            }
            .padding()

            Text(userName.isEmpty ? "Your Name" : userName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 15) {
                        CustomTextField(placeholder: "Full Name", text: $userName)
                        CustomTextField(placeholder: "Phone Number", text: $phoneNumber, keyboardType: .phonePad)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Carpool Message")
                                .font(.headline)
                                .foregroundColor(.blue)
                            TextEditor(text: $carpoolMessage)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                        }
                    }

                    VStack(spacing: 15) {
                        Button(action: {
                            saveUserProfile()
                        }) {
                            Text("Save Profile")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            isLoggedIn = false
                        }) {
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            loadUserProfile()
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $profileImage)
        }
    }

    private func loadUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        let docRef = db.collection("users").document(user.email ?? "")
        docRef.getDocument { document, _ in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                phoneNumber = data["phoneNumber"] as? String ?? ""
                userName = data["userName"] as? String ?? ""
                carpoolMessage = data["carpoolMessage"] as? String ?? ""
            }
        }
    }

    private func saveUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        let userProfileData: [String: Any] = [
            "phoneNumber": phoneNumber,
            "userName": userName,
            "carpoolMessage": carpoolMessage
        ]

        db.collection("users").document(user.email ?? "").setData(userProfileData)
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading) {
            Text(placeholder)
                .font(.headline)
                .foregroundColor(.blue)
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.selectedImage = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
