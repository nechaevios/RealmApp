//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Nechaev Sergey  on 09.10.2021.
//

import RealmSwift

class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(for: task) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let changeStatusActionTitle = indexPath.section == 0 ? "Done" : "Undone"
        let sectionToInsert = indexPath.section == 0 ? completedTasks : currentTasks
        let sectionIndex = indexPath.section == 0 ? 1 : 0
        
        let changeStatusAction = UIContextualAction(style: .normal, title: changeStatusActionTitle)
        {_, _, isDone in
            indexPath.section == 0 ? StorageManager.shared.done(task) : StorageManager.shared.undone(task)
            let rowIndex = IndexPath(row: sectionToInsert?.index(of: task) ?? 0, section: sectionIndex)
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.insertRows(at: [rowIndex], with: .automatic)
            tableView.endUpdates()
            
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        changeStatusAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [changeStatusAction, editAction, deleteAction])
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
}

extension TasksViewController {
    
    private func showAlert(for task: Task? = nil, completion: (() -> Void)? = nil) {
        let title = task != nil ? "Update task" : "New Task"
        let alert = AlertController.createAlert(withTitle: title, andMessage: "What do you want to do?")
        
        
        alert.action(for: task) { newValue, note in
            if let task = task, let completion = completion {
                StorageManager.shared.edit(task, newName: newValue, newNote: note)
                completion()
            } else {
                self.saveTask(withName: newValue, andNote: note)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func saveTask(withName name: String, andNote note: String) {
        let task = Task(value: [name, note])
        StorageManager.shared.save(task, to: taskList)
        let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
}

