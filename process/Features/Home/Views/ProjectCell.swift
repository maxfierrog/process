//
//  ProjectCell.swift
//  process
//
//  Created by maxfierro on 7/27/22.
//


import SwiftUI


struct ProjectCellView: View {
    
    @ObservedObject var model: ProjectCellViewModel
    
    var body: some View {
        GroupBox {
            VStack {
                HStack {
                    Text(model.formattedDescription())
                        .font(.footnote)
                    Spacer()
                }
                .padding(.top, 1)
                Spacer()
                HStack {
                    ForEach($model.collaboratorPictures.indices, id: \.self) { index in
                        ProfilePictureView(picture: $model.collaboratorPictures[index],
                                           width: 32,
                                           height: 32,
                                           border: 2,
                                           shadow: 1)
                            .padding(.init(top: 1, leading: 1, bottom: 1, trailing: 0))
                    }
                    Spacer()
                }
                HStack {
                    ProgressView(model.formattedCreationDate(),
                                 value: Float(model.completedTaskCount()),
                                 total: Float(model.project.taskList.allTasks.count))
                        .progressViewStyle(.linear)
                        .font(.caption2)
                }
                .padding(.top, 2)
            }
            .frame(height: 110)
        } label: {
            Text(model.project.data.name)
        }
    }
}


class ProjectCellViewModel: ObservableObject {
    
    @Published var project: Project = Project(creatorID: "")
    @Published var collaboratorPictures: [UIImage] = []
    
    init(project: Project) {
        self.project = project
        for index in project.data.collaborators.indices {
            self.collaboratorPictures.append(UIImage(named: ProfileConstant.defaultProfilePicture)!)
            APIHandler.pullProfilePicture(userID: project.data.collaborators[index]) { error, image in
                guard error == nil else { return }
                self.collaboratorPictures[index] = image!
            }
        }
    }
    
    func formattedDescription() -> String {
        var description: String = project.data.description ?? ""
        if description.count > 30 {
            description = String((description).prefix(30)) + "..."
        }
        return description
    }
    
    func formattedCreationDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateFormatter.timeZone = NSTimeZone(name: "PST")! as TimeZone
        return "Started " + dateFormatter.string(from: project.data.dateCreated)
    }
    
    func completedTaskCount() -> Int {
        var count: Int = 0
        for task in project.taskList.allTasks {
            if task.data.dateCompleted != nil {
                count += 1
            }
        }
        return count
    }
}


struct ProjectCell_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(model: HomeViewModel(RootViewModel()))
    }
}
