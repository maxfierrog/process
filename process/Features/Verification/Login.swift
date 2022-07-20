//
//  Login.swift
//  process
//
//  Created by Maximo Fierro on 7/11/22.
//


import SwiftUI
import ActionButton
import Combine
import FirebaseAuth


/** Ennumaeration of focusable areas on login screen, allowing for
 quick traversal of fields using the 'next' button on keyboard. */
enum FocusableLoginField: Hashable {
    case emailField
    case passwordField
}


/** Allows client to sign-in an existing user, handling credential verification
 with API calls through the view model. Provides comprehensive error messages
 through banners. */
struct LoginView: View {
    
    /* MARK: Struct fields */
    
    @StateObject var model: LoginViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focus: FocusableLoginField?
    
    /* MARK: View declaration */
    
    var body: some View {
        NavigationView {
            GroupBox {
                NavigationLink(destination: RegistrationView(model: RegistrationViewModel(model)),
                               tag: true,
                               selection: $model.navigateToRegister) { }
                
                VStack (alignment: .center, spacing: 10, content: {
                    Image("login-image")
                        .resizable()
                        .scaledToFit()
                    
                    EmailField(title: "Email", text: $model.emailField)
                        .padding(.bottom, 10)
                        .submitLabel(.next)
                        .focused($focus, equals: .emailField)
                        .onSubmit {
                            focus = .passwordField
                        }
                    
                    PasswordField(title: "Password", text: $model.passwordField)
                        .padding(.bottom, 20)
                        .focused($focus, equals: .passwordField)
                        .submitLabel(.go)
                })
                
                ActionButton(state: $model.loginButtonState, onTap: {
                    model.loginUser()
                }, backgroundColor: colorScheme == .dark ? .indigo : .primary)
                
                Text("or")
                    .bold()
                    .font(.subheadline)
                
                ActionButton(state: $model.registerButtonState, onTap: {
                    model.didTapRegister()
                }, backgroundColor: colorScheme == .dark ? .brown : .primary)
                
                Button {
                    model.sendPasswordResetEmail()
                } label: {
                    Text(LoginConstant.forgotPasswordButtonText)
                        .underline()
                }
                .font(.footnote)
                .padding(.top, 5)
            } label: {
                Label(LoginConstant.welcomeMessage, systemImage: LoginConstant.welcomeIcon)
            }
            .padding()
            .navigationTitle(LoginConstant.navigationTitle)
        }
        .accentColor(GlobalConstant.accentColor)
        .banner(data: $model.bannerData, show: $model.showErrorBanner)
    }
}


/** Handles UI state tracking and updating, credential validation, initial
 navigation, and dispatches API calls. */
class LoginViewModel: ObservableObject {
    
    /* MARK: Model fields */
    
    // SuperView model
    @Published var superModel: SuperViewModel
        
    // Navigation fields
    @Published var navigateToHome: Bool? = false
    @Published var verifiedUser: User = User()
    
    // Data fields
    @Published var passwordField: String = ""
    @Published var emailField: String = ""
    @Published var navigateToRegister: Bool? = nil
    
    // UI state fields
    @Published var loginButtonState: ActionButtonState = LoginConstant.invalidLoginButtonState
    @Published var registerButtonState: ActionButtonState = .enabled(title: LoginConstant.registerButtonTitle, systemImage: LoginConstant.registerButtonIcon)
    @Published var showErrorBanner: Bool = false
    @Published var bannerData: BannerModifier.BannerData = BannerModifier.BannerData(title: "", detail: "", type: .Info)
    
    // Publisher fields
    private var cancellables: Set<AnyCancellable> = []
    private var emailIsValidPublisher: AnyPublisher<Bool, Never> {
        $emailField
            .map { value in
                VerificationUtils.isValidEmail(value)
            }
            .eraseToAnyPublisher()
    }
    private var passwordIsValidPublisher: AnyPublisher<Bool, Never> {
        $passwordField
            .map { value in
                !value.isEmpty
            }
            .eraseToAnyPublisher()
    }
    
    /* MARK: Model methods */
    
    init(_ superModel: SuperViewModel) {
        self.superModel = superModel
        emailIsValidPublisher
            .combineLatest(passwordIsValidPublisher)
            .map { emailValid, passwordValid in
                emailValid && passwordValid
            }
            .map { fieldsValid -> ActionButtonState in
                if fieldsValid {
                    return LoginConstant.enabledLoginButtonState
                }
                return LoginConstant.invalidLoginButtonState
            }
            .assign(to: \.loginButtonState, on: self)
            .store(in: &cancellables)
    }
    
    /** First authenticates with email and password credentials, then fetches
     user data model from database, and passes it to SuperModel, who handles
     navigation to home. */
    func loginUser() {
        loginButtonState = LoginConstant.loadingLoginButtonState
        Auth.auth().signIn(withEmail: emailField, password: passwordField) { [weak self] authResult, error in
            guard error == nil else {
                self?.loginButtonState = LoginConstant.failedLoginButtonState
                return
            }
            APIHandler.getUserFromEmail(self!.emailField) { user, error in
                guard error == nil else {
                    self?.loginButtonState = LoginConstant.failedLoginButtonState
                    self?.showBannerWithErrorMessage(error!.localizedDescription)
                    return
                }
                self?.verifiedUser = user!
                self?.loginButtonState = LoginConstant.successLoginButtonState
                self?.superModel.loginWithUserModel(user!)
            }
        }
    }
    
    func sendPasswordResetEmail() {
        guard VerificationUtils.isValidEmail(emailField) else {
            showBannerWithErrorMessage(LoginConstant.invalidEmailForResetText)
            return
        }
        Auth.auth().sendPasswordReset(withEmail: emailField) { error in
            guard error == nil else {
                self.showBannerWithErrorMessage(error?.localizedDescription)
                return
            }
            self.bannerData.title = LoginConstant.recoveryEmailSentBannerTitle
            self.bannerData.detail = LoginConstant.recoveryEmailSentText
            self.bannerData.type = .Info
            self.showErrorBanner = true
        }
    }
    
    func didTapRegister() {
        showErrorBanner = false
        navigateToRegister = true
    }
    
    func superLoginUserWithModel(_ model: User) {
        self.superModel.loginWithUserModel(model)
    }
    
    /* MARK: Model helper methods */
    
    private func showBannerWithErrorMessage(_ message: String?) {
        guard let message = message else { return }
        bannerData.title = LoginConstant.genericErrorBannerTitle
        bannerData.detail = message
        bannerData.type = .Error
        showErrorBanner = true
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(model: LoginViewModel(SuperViewModel()))
    }
}
