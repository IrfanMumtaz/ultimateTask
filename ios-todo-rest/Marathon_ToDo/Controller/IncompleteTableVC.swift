//
//  IncompleteTableVC.swift
//  Marathon-ToDo
//
//  Created by Syed ShahRukh Haider on 17/09/2018.
//  Copyright © 2018 Syed ShahRukh Haider. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Alamofire
import SwiftyJSON

class IncompleteTableVC: UIViewController {

    @IBOutlet weak var IncompleteTable: UITableView!
   
    var displayData = [[String : String]]()
    var ShareData = UIApplication.shared.delegate as! AppDelegate
    var tasks = [Task]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        IncompleteTable.delegate = self
        IncompleteTable.dataSource = self
       
        if  ShareData.incompleteDatabse.isEmpty == false{
            self.displayData = ShareData.incompleteDatabse
        }
        
        IncompleteTable.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        IncompleteTable.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.displayData = ShareData.incompleteDatabse

        let url = "http://rest-nosql.herokuapp.com/todo/api/v1/tasks"
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in

            do {
                let json = try? JSON(data: response.data!)
                let result = json?["result"]
                let tasks = try JSONDecoder().decode([Task].self, from: result!.rawData())
                DispatchQueue.main.async {
                    self.tasks = tasks.filter({ $0.task_done == "false"})
                    self.IncompleteTable.reloadData()
                }
            }catch let error {
                print(error)
            }
        }

    }
    
    @objc func deleteTask(button : UIButton){
        let index = button.tag
        self.displayData.remove(at: index)
        self.ShareData.incompleteDatabse.remove(at: index)
        self.IncompleteTable.reloadData()
    }
    
    @objc func editTask(button : UIButton) {
        let index = button.tag
        
        let option = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // EDIT
        let EditButton = UIAlertAction(title: "Edit", style: .default) { (action) in
          //  let selectedIndex = index
            self.performSegue(withIdentifier: "Edit_Segue", sender: self.tasks[index])
        }
        option.addAction(EditButton)

        // COMPLETE
        let Complete = UIAlertAction(title: "Completed", style:.default) { (action) in

            self.displayData[index]["Status"] = "Complete"
            self.ShareData.completeDatabase.append(self.displayData[index])
            self.displayData.remove(at: index)
            self.ShareData.incompleteDatabse.remove(at: index)
            self.IncompleteTable.reloadData()
        }
        option.addAction(Complete)

        // CANCEL
        let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        option.addAction(cancel)

        self.present(option, animated: true, completion: nil)
    }
    
    // ****** Prepare Segue ****************
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Edit_Segue"{
            let dest = segue.destination as! CreateTodo
            dest.segueName = "Edit"
           // dest.selectedIndex = sender as! Task
            dest.task = sender as! Task
        }
    }
}

extension IncompleteTableVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IncompleteCell", for: indexPath) as! IncompleteTableViewCell
        
        tableView.separatorStyle = .none
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.clear
        
        let task = self.tasks[indexPath.row]
        
        cell.incompleteTitle.text = task.task_title
        cell.incompleteDescription.text = task.task_description
        
        cell.delete.tag = indexPath.row
        cell.edit.tag = indexPath.row
        
        cell.delete.addTarget(self, action: #selector(self.deleteTask), for: .touchUpInside)
        cell.edit.addTarget(self, action: #selector(editTask), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            self.displayData.remove(at: indexPath.row)
            self.ShareData.incompleteDatabse.remove(at: indexPath.row)
            self.IncompleteTable.reloadData()
        }
    }
}

extension IncompleteTableVC : IndicatorInfoProvider{
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Incomplete")
    }
}
