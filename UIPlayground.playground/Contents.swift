//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport


class MyViewController : UIViewController {
    
    var mainView: UIView!
    var bottomSheet: UIView!
    var menusheet: UIView!
    var hitogramLayer: CALayer!
    
    var cha: CGFloat!
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .black
        self.view = view
        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupUI()
        setupMenuSheet()
        
        print("menu \(menusheet.frame.minY) - \(menusheet.frame.maxY)")
        print("bottom \(bottomSheet.frame.minY) - \(bottomSheet.frame.maxY)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("menu \(menusheet.frame.minY) - \(menusheet.frame.maxY)")
        print("bottom \(bottomSheet.frame.minY) - \(bottomSheet.frame.maxY)")
        
        cha = bottomSheet.frame.minY - menusheet.frame.maxY
    }
    
    func setupUI() {
        //setup main view
        mainView = UIView()
        mainView.backgroundColor = .gray
        mainView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainView)
        
        NSLayoutConstraint.activate([
            mainView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            mainView.widthAnchor.constraint(equalTo: view.widthAnchor),
            mainView.topAnchor.constraint(equalTo: view.topAnchor),
            mainView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            
        ])
        
        //setup menu sheet
        menusheet = UIView(frame: .zero)
        menusheet.backgroundColor = .white
        menusheet.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(menusheet)
        
        NSLayoutConstraint.activate([
            menusheet.heightAnchor.constraint(equalToConstant: 80),
            menusheet.widthAnchor.constraint(equalTo: view.widthAnchor),
            menusheet.topAnchor.constraint(equalTo: mainView.bottomAnchor),
            menusheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menusheet.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        menusheet.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(swipe(_:))))
        
        // setup bottom sheet
        bottomSheet = UIView()
        bottomSheet.backgroundColor = #colorLiteral(red: 0.1678462625, green: 0.1708839238, blue: 0.1609433293, alpha: 1)
        bottomSheet.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(bottomSheet)
        
        NSLayoutConstraint.activate([
            bottomSheet.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.22),
            bottomSheet.widthAnchor.constraint(equalTo: view.widthAnchor),
            bottomSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hitogramLayer = CALayer()
        hitogramLayer.contents = UIImage(named: "pencil")?.cgImage
        hitogramLayer.frame = CGRect(x: 20, y: 30, width: 100, height: 50)
        hitogramLayer.backgroundColor = UIColor.black.cgColor
    }
    
    @objc func swipe(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            print("changed:")
            print("menu \(menusheet.frame.minY) - \(menusheet.frame.maxY)")
            print("bottom \(bottomSheet.frame.minY) - \(bottomSheet.frame.maxY)")
            
    
            print("\(recognizer.translation(in: view))")
            if(recognizer.translation(in: view).y > 0) {
                menusheet.transform = CGAffineTransform(translationX: 0, y: 0)
            } else if (recognizer.translation(in: view).y > cha){
                menusheet.transform = CGAffineTransform(translationX: 0, y: recognizer.translation(in: view).y)
            }
        case .ended:
            print("ended: \(menusheet.frame.maxY - bottomSheet.frame.minY)")
            if recognizer.translation(in: view).y > 0 {
                menusheet.transform = CGAffineTransform(translationX: 0, y: 0)
            } else {
                menusheet.transform = CGAffineTransform(translationX: 0, y: cha)
            }
        default:
            break
        }
    }
    
    
    func setupMenuSheet() {
        
        let imageView = UIImageView(image: UIImage(systemName: "chevron.up"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .red
        
        menusheet.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.centerXAnchor.constraint(equalTo: menusheet.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: menusheet.topAnchor, constant: 5)
        ])
        
        let gridButton = UIButton(frame: .zero)
        
        gridButton.setImage(UIImage(systemName: "squareshape.split.3x3"), for: .normal)
        gridButton.translatesAutoresizingMaskIntoConstraints = false
        
        menusheet.addSubview(gridButton)
        
        NSLayoutConstraint.activate([
            gridButton.heightAnchor.constraint(equalToConstant: 30),
            gridButton.widthAnchor.constraint(equalToConstant: 30),
            gridButton.centerXAnchor.constraint(equalTo: menusheet.centerXAnchor),
            gridButton.topAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        
        
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
