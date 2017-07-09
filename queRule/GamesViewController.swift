import UIKit
import CoreData

class GamesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    var manageObjectContext : NSManagedObjectContext? = nil
    var listGames : [Game] = [Game]()
    
    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        performGamesQuery()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.alwaysBounceVertical = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performGamesQuery()
    }
    
    //Get games from CoreData
    func performGamesQuery() {
        
        let request : NSFetchRequest<Game> = Game.fetchRequest()
        let sortByDate : NSSortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: false)
        
        request.sortDescriptors = [sortByDate]
        
        if filterControl.selectedSegmentIndex == 0 {
            let predicate : NSPredicate = NSPredicate(format: "borrowed = true")
            request.predicate = predicate
        }
        
        do {
            let fetchedGames = try manageObjectContext?.fetch(request)
            
            if let fetchedGames = fetchedGames {
                listGames = fetchedGames
                collectionView.reloadData()
            }
        } catch {
            print("Error recuperando datos de Core Data")
        }
    }

    func  formatColours(string: String, color: UIColor) -> NSMutableAttributedString {
        
        let length = string.characters.count
        let colonPosition = string.indexOf(target: ":")!
        let myMutableString = NSMutableAttributedString(string: string, attributes: nil)
        
        myMutableString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange(location: 0, length: length))
        myMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: NSRange(location: 0, length: colonPosition + 1))
        
        return myMutableString
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if listGames.count == 0 {
            let imageView : UIImageView = UIImageView(image: #imageLiteral(resourceName: "img_empty_screen"))
            imageView.contentMode = .center
            collectionView.backgroundView = imageView
        } else {
            collectionView.backgroundView = UIView()
        }
        
        return listGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCell
        let game = listGames[indexPath.row]
        var highlightColor = #colorLiteral(red: 0.9058823529, green: 0.2980392157, blue: 0.2352941176, alpha: 1)
        
        if !game.borrowed {
            highlightColor = #colorLiteral(red: 0.2039215686, green: 0.5960784314, blue: 0.8588235294, alpha: 1)
        }
        
        cell.lblTitle.text = game.title
        cell.lblBorrowed.attributedText = self.formatColours(string: "PRESTADO: \(game.borrowed ? "SI" : "NO")", color: highlightColor)
        
        if let borrowedTo = game.borrowedTo {
            cell.lblBorrowedTo.attributedText = self.formatColours(string: "A: \(borrowedTo)", color: highlightColor)
        } else {
            cell.lblBorrowedTo.attributedText = self.formatColours(string: "A: --", color: highlightColor)
        }
        
        if let borrowedDate = game.borrowedDate as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            
            cell.lblBorrowedDate.attributedText = self.formatColours(string: "FECHA: \(dateFormatter.string(from: borrowedDate))", color: highlightColor)
        } else {
            cell.lblBorrowedDate.attributedText = self.formatColours(string: "FECHA: --", color: highlightColor)
        }
        
        if let image = game.image as? Data {
            cell.imageView.image = UIImage(data: image)
        }
        
        cell.layer.masksToBounds = false
        cell.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.2
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width - 20, height: 120.0)
    }
    
    //An item has been selected from collection view
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editGameSegue", sender: self)
    }
    
    //A user do scroll on collection, pulling down
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        if offsetY < -120 {
            performSegue(withIdentifier: "addGameSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGameSegue" {
            let addNavVC = segue.destination as! UINavigationController
            let addVC = addNavVC.topViewController as! AddGameViewController
            addVC.managedObjectContext = self.manageObjectContext
            addVC.delegate = self
            
        } else if segue.identifier == "editGameSegue" {
            let addGameVC = segue.destination as! AddGameViewController
            addGameVC.managedObjectContext = self.manageObjectContext
            addGameVC.delegate = self
            
            let selectedIndex = collectionView.indexPathsForSelectedItems?.first?.row
            let game = listGames[selectedIndex!]
            addGameVC.game = game
        }
    }
}

extension String {
    func indexOf(target: String) -> Int? {
        if let range = self.range(of: target) {
            return self.distance(from: self.startIndex, to: range.lowerBound)
        }
        return nil
    }
}

extension GamesViewController : AddGameViewControllerDelegate {
    func didAddGame() {
        self.collectionView.reloadData()
    }
}


