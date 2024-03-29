//
//  ProfileCardView.swift
//  process
//
//  Created by maxfierro on 7/25/22.
//


import SwiftUI


/** A display card containing user identifying data. */
struct ProfileCardView: View {
    
    @StateObject var model: ProfileHomeViewModel
    
    /* MARK: Profile card view */
    
    var body: some View {
        GroupBox {
            HStack {
                Spacer()
                ProfilePictureView(picture: $model.profilePictureImage,
                                   width: 100,
                                   height: 100,
                                   border: 4,
                                   shadow: 7)
                    .padding(.init(top: 8, leading: 8, bottom: 8, trailing: 10))
                VStack {
                    HStack {
                        Text(model.editorNameField)
                            .font(.title2)
                            .bold()
                    }
                    HStack {
                        Text(model.editorUsernameField)
                            .font(.title3)
                            .padding(.bottom, 3)
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
}
