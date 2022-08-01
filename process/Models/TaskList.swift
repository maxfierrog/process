//
//  TaskList.swift
//  process
//
//  Created by maxfierro on 7/25/22.
//


import Foundation

enum Sort: String, CaseIterable, Identifiable {
    case creationDate
    case dueDate
    case size
    case topological
    case any
    var id: Self { self }
}

/** */
class TaskCollection {
    
    /* MARK: Fields */
    
    private var tasks: Set<Task> = []
    
    /* MARK: Methods */
    
    func insertTask(_ task: Task) {
        tasks.insert(task)
    }
    
    func list(_ sort: Sort?) -> [Task] {
        switch sort {
        case .creationDate:
            return Array(self.tasks).sorted { task1, task2 in
                return task1.data.dateCreated > task2.data.dateCreated // FIXME: Compare dates as strings
            }
        case .dueDate:
            return Array(self.tasks).sorted { task1, task2 in
                return task1.data.dateDue > task2.data.dateDue // FIXME: Compare dates as strings
            }
        case .size:
            return Array(self.tasks).sorted { task1, task2 in
                return task1.data.size > task2.data.size // FIXME: Might be the wrong way around
            }
        default:
            return Array(self.tasks)
        }
    }
}
