//
//  ProjectDetails.swift
//  process
//
//  Created by Maximo Fierro on 7/11/22.
//

import SwiftUI

struct ProjectDetailsView: View {
    
    @ObservedObject var model: ProjectDetailsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    /* MARK: View declaration */
    
    var body: some View {
        VStack {
            NavigationLink(destination: TaskDetailsView(model: TaskDetailsViewModel(model)), tag: true, selection: $model.navigateToTaskDetails) { }
            
            HStack {
                Text(model.project.data.description ?? "")
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            SearchBar(searchText: $model.searchText, isEditingSearch: $model.isEditingSearch, sortSelection: $model.sortSelection)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            SegmentedPicker(accessibilityText: TasksConstant.pickerAccessibilityText,
                            categories: model.taskCategories,
                            selectedCategory: $model.selectedTaskCategory)
                .padding(.horizontal)
                .padding(.bottom)
            
            TaskListView(model: TaskListViewModel(model))
                .padding(.horizontal)
        }
        .roundButton(
            color: GlobalConstant.accentColor,
            image: Image(systemName: "plus").foregroundColor(colorScheme == .dark ? .black : .white)) {
            model.tappedNewTask()
        }
        .accentColor(GlobalConstant.accentColor)
        .onAppear(perform: model.refreshTaskList)
        .banner(data: $model.bannerData, show: $model.showBanner)
        .toolbar {
//            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                Button {
//                    model.tappedAddCollaborator()
//                } label: {
//                    Label("Add collaborator", systemImage: "person.fill.badge.plus")
//                }
//                Button {
//                    model.tappedEditProject()
//                } label: {
//                    Label("Edit project", systemImage: "square.and.pencil")
//                }
//            }
        }
        .sheet(isPresented: $model.navigateToNewTask) {
            NavigationView {
                NewTaskView(model: NewTaskViewModel(model))
            }
        }
        .navigationTitle(model.project.data.name)
    }
}

class ProjectDetailsViewModel: TaskListParent, ObservableObject {
    
    /* MARK: Model fields */
    
    var parentViewModel: ProjectsHomeViewModel
    
    // Navigation
    @Published var navigateToTaskDetails: Bool? = false
    @Published var navigateToNewTask: Bool = false
    @Published var navigateToEditProject: Bool? = false
    @Published var navigateToAddCollaborator: Bool? = false
    
    // Parent model
    @Published var project: Project = Project(creatorID: "")
    @Published var user: User
    
    // Search bar
    @Published var isEditingSearch: Bool = false
    @Published var searchText: String = ""
    @Published var sortSelection: TaskSort = .none
    
    // Segmented picker
    @Published var taskCategories: [String] = ["Unassigned", "Assigned", "Done"]
    @Published var selectedTaskCategory: Int = 0
    
    // Task list
    @Published var selectedTask: Task = Task(creatorID: "")
    @Published var taskList: AsyncTaskList
    
    // Banner state fields
    @Published var showBanner: Bool = false
    @Published var bannerData: BannerModifier.BannerData = BannerModifier
        .BannerData(title: "", detail: "", type: .Info)
    
    /* MARK: Model initializer */
    
    init(_ model: ProjectsHomeViewModel) {
        self.user = model.user
        self.parentViewModel = model
        self.project = model.selectedProject
        self.taskList = model.selectedProject.taskList
    }
    
    /* MARK: Model action methods */
    
    func tappedTask() {
        self.navigateToTaskDetails = true
    }
    
    func tappedNewTask() {
        self.navigateToNewTask = true
    }
    
    func tappedEditProject() {
        self.navigateToEditProject = true
    }
    
    func tappedAddCollaborator() {
        self.navigateToAddCollaborator = true
    }
    
    func dismissChildView(_ named: String) {
        switch named {
        case "NewTaskView":
            self.navigateToNewTask = false
        case "EditProjectView":
            self.navigateToEditProject = false
        case "AddCollaboratorsView":
            self.navigateToAddCollaborator = false
        default:
            return
        }
    }
    
    /* MARK: Model helper methods */
    
    func refreshTaskList() {
//        self.taskList = AsyncTaskList(self.project.data.tasks) // FIXME: Might not update properly
    }
    
    func showBannerWithSuccessMessage(_ message: String?) {
        guard let message = message else { return }
        bannerData.title = GlobalConstant.genericSuccessBannerTitle
        bannerData.detail = message
        bannerData.type = .Success
        showBanner = true
    }
    
    
}

struct ProjectDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(model: HomeViewModel(RootViewModel()))
    }
}
