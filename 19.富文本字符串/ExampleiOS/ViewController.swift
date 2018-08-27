//
//  ViewController.swift
//  ExampleiOS
//
//  Created by Daniele Margutti on 05/05/2018.
//  Copyright © 2018 SwiftRichString. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	@IBOutlet public var label: UILabel?

	override func viewDidLoad() {
		super.viewDidLoad()
		
        let str = "77777"
		self.label?.styledText = "Hello <red>\(str)</red>"
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

