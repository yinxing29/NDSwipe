//
//  ViewController.swift
//  NDSwipe
//
//  Created by yinxing on 2022/6/23.
//

import UIKit

class ViewController: UIViewController {
    
    private let cellIdentify = "nd_cell_identify"
    
    private let defaultCellIdentify = "default_cell_identify"
    
    private let ScreenWidth = UIScreen.main.bounds.size.width
    
    private lazy var tableView: UITableView = {
        let tab = UITableView(frame: view.bounds, style: .plain)
        tab.rowHeight = (ScreenWidth - 40) * 290 / 320.0 + 20.0
        tab.delegate = self
        tab.dataSource = self
        tab.tableFooterView = UIView(frame: .zero)
        
        tab.register(NDTableViewCell.self, forCellReuseIdentifier: cellIdentify)
        tab.register(UITableViewCell.self, forCellReuseIdentifier: defaultCellIdentify)
        return tab
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
    }
}

//MARK: <UITableViewDataSource, UITableViewDataSource>
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentify, for: indexPath) as! NDTableViewCell
            
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellIdentify, for: indexPath)
        cell.textLabel?.text = "index\(indexPath.row)"
        return cell
    }
}
