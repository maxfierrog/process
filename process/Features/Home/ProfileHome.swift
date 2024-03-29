//
//  ProfileHome.swift
//  process
//
//  Created by Maximo Fierro on 7/11/22.
//


import SwiftUI


/** Allows the user to view and edit their personally identifying information,
 and to interface with account and privacy preferences. */
struct ProfileHomeView: View {
    
    @StateObject var model: ProfileHomeViewModel
    @Environment(\.colorScheme) private var colorScheme

    /* MARK: Profile home view */
    
    var body: some View {
        VStack {
            NavigationLink(destination: UserPreferencesView(), tag: true, selection: $model.navigateToPreferences) { }
            if (model.editing) {
                EditProfileCardView(model: model)
            }
            ProfileCardView(model: model)
                .onLongPressGesture {
                    withAnimation {
                        model.tappedEditProfile()
                    }
                }
//            if (!model.editing) {
//                AnalyticsScrollView(model: model)
//            }
            Spacer()
        }
        .accentColor(GlobalConstant.accentColor)
        .banner(data: $model.bannerData, show: $model.showBanner)
        .toolbar {
//            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                Button {
//                    model.tappedPreferences()
//                } label: {
//                    Label(ProfileConstant.preferencesAccessibilityText, systemImage: ProfileConstant.preferencesButtonIcon)
//                }
//            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    withAnimation {
                        model.tappedLogOut()
                    }
                } label: {
                    Text(GlobalConstant.logoutButtonText)
                }
            }
        }
        .sheet(isPresented: $model.navigateToChoosePhoto) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $model.profilePictureImage)
        }
    }
}


/** Data model for all profile Views. Communicates with Home view's model to
 obtain data and to communicate instructions, such as logging out. */
class ProfileHomeViewModel: ObservableObject {
    
    /* MARK: Model fields */
    
    // HomeView parent model
    var homeViewModel: HomeViewModel
    @Published var user: User
    
    // Navigation
    @Published var navigateToPreferences: Bool? = false
    @Published var navigateToChoosePhoto: Bool = false
    
    // Banner state fields
    @Published var bannerData: BannerModifier.BannerData = BannerModifier.BannerData(title: "", detail: "", type: .Info)
    @Published var showBanner: Bool = false
    
    // Profile editing
    @Published var editing: Bool = false
    @Published var profilePictureImage: UIImage
    @Published var editorUsernameField: String
    @Published var editorNameField: String
    
    /* MARK: Model methods */
    
    init(_ model: HomeViewModel) {
        self.homeViewModel = model
        self.user = model.user
        self.editorNameField = model.user.data.name
        self.editorUsernameField = model.user.data.username
        self.profilePictureImage = model.user.profilePicture
    }
    
    /* MARK: User data methods */
    
    func getProfilePicture() -> UIImage {
        return self.profilePictureImage
    }
    
    func tappedEditProfile() {
        if self.editing {
            self.editorNameField = self.user.data.name
            self.editorUsernameField = self.user.data.username
            self.profilePictureImage = self.user.profilePicture
        }
        self.editing.toggle()
    }
    
    func saveUserData() {
        guard self.user.data.username != self.editorUsernameField else {
            self.updateUserModel()
            self.editing = false
            return
        }
        APIHandler.matchUsernameQuery(self.editorUsernameField) { result, error in
            guard error == nil else {
                self.showBannerWithErrorMessage(error?.localizedDescription)
                return
            }
            guard result!.documents.isEmpty else {
                self.showBannerWithErrorMessage(ProfileConstant.usernameColisionError)
                return
            }
            self.updateUserModel()
            self.editing = false
        }
    }
    
    func updateUserModel() {
        self.user
            .changeName(self.editorNameField)
            .changeUsername(self.editorUsernameField)
            .push { error in
                guard error == nil else {
                    self.showBannerWithErrorMessage(error?.localizedDescription)
                    return
                }
                self.uploadProfilePicture(self.profilePictureImage)
                self.showBannerWithSuccessMessage("We have updated your profile!")
            }
    }
    
    /* MARK: Action methods */
    
    func tappedChooseProfilePicture() {
        self.navigateToChoosePhoto = true
    }
    
    func tappedPreferences() {
        self.navigateToPreferences = true
    }
    
    func tappedLogOut() {
        if (!self.homeViewModel.logOut()) {
            self.showBannerWithErrorMessage(GlobalConstant.logOutFailedBannerMessage)
        }
    }
    
    /* MARK: Helper methods */
    
    private func showBannerWithErrorMessage(_ message: String?) {
        guard let message = message else { return }
        bannerData.title = GlobalConstant.genericErrorBannerTitle
        bannerData.detail = message
        bannerData.type = .Error
        showBanner = true
    }
    
    private func showBannerWithSuccessMessage(_ message: String?) {
        guard let message = message else { return }
        bannerData.title = GlobalConstant.genericSuccessBannerTitle
        bannerData.detail = message
        bannerData.type = .Success
        showBanner = true
    }
    
    private func uploadProfilePicture(_ image: UIImage) {
        self.user.pushProfilePicture(image) { error in
            guard error == nil else {
                self.showBannerWithErrorMessage(error?.localizedDescription)
                return
            }
            self.showBannerWithSuccessMessage(ProfileConstant.successUpdatingData)
        }
    }
}

struct ProfileHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHomeView(model: ProfileHomeViewModel(HomeViewModel(RootViewModel())))
    }
}
