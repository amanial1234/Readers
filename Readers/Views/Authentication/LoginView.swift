import SwiftUI

struct LoginView: View {
    @ObservedObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App logo/title
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Readers")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your personal reading journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Form fields
                VStack(spacing: 20) {
                    if isSignUp {
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Action button
                    Button(action: performAction) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                }
                
                // Toggle between sign in and sign up
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 50)
        }
        .environmentObject(appState)
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !displayName.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func performAction() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isSignUp {
                    try await appState.signUp(email: email, password: password, displayName: displayName)
                } else {
                    try await appState.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

#Preview {
    LoginView(appState: AppState())
} 