import UIKit
import CoreData
import AVFoundation

protocol AddGameViewControllerDelegate {
    
    func didAddGame()
}

class AddGameViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var gameImageView: UIImageView!
    @IBOutlet weak var borrowedSwitch: UISwitch!
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtBorrowedTo: UITextField!
    @IBOutlet weak var txtBorrowedDate: UITextField!
    @IBOutlet weak var btnDelete: UIButton!
    
    var managedObjectContext : NSManagedObjectContext? = nil
    
    var imagePickerController = UIImagePickerController()
    var cameraPermissions : Bool = false
    
    var delegate : AddGameViewControllerDelegate?
    
    var game : Game? = nil
    
    var datePicker : UIDatePicker!
    var dateFormatter = DateFormatter()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        /*Keyboard*/
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        
        let takePictureGesture = UITapGestureRecognizer(target: self, action: #selector(takePictureTapped))
        self.gameImageView.addGestureRecognizer(takePictureGesture)
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 216))
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerChangedValue), for: .valueChanged)
        txtBorrowedDate.inputView = datePicker
        
        if game == nil {
            self.title = "Añadir juego"
            
            //Add buttons to save or cancel the new game
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            
            self.btnDelete.isHidden = true
            self.borrowedSwitch.isOn = false
            
        } else {
            self.title = "Detalles"
            
            //Set the game properties
            self.txtTitle.text = game?.title
            
            if let borrowed = game?.borrowed {
                self.borrowedSwitch.isOn = borrowed
            }
            
            self.txtBorrowedTo.text = game?.borrowedTo
            if let borrowedDate = game?.borrowedDate as? Date {
                self.txtBorrowedDate.text = dateFormatter.string(from: borrowedDate)
            }
            
            if let imageData = game?.image as? Data {
                self.gameImageView.image = UIImage(data: imageData)
            }
            
            self.btnDelete.isHidden = false
        }
        
        if(!self.borrowedSwitch.isOn) {
            self.txtBorrowedTo.isEnabled = false
            self.txtBorrowedDate.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if game != nil {
            saveGame()
        }
    }
    
    /*Function invoked when keyboard will show*/
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        
        //Get the keyboard frame size and the keyboard animation duration
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime: Double = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        //Move our view up the same frame size and animation time of keyboard
        UIView.animate(withDuration: keyboardTime) { 
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
    }
    
    /*Function invoked when keyboard will hide*/
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo!
        
        //Get the keyboard animation duration
        let keyboardTime: Double = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        //Move our view down the same frame size and animation time of keyboard
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
    }
    
    /*Function invoked when user tap the main view to hide the keyboard*/
    func viewTapped() {
        for view in self.view.subviews {
            if let textField = view as? UITextField {
                textField.resignFirstResponder()
            }
        }
    }
    
    func checkPermissions() {
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .authorized:
            cameraPermissions = true
        case .restricted:
            cameraPermissions = false
        case .denied:
            cameraPermissions = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType, completionHandler: { (granted) in
                self.cameraPermissions = granted
            })
        }
    }
    
    func takePictureTapped() {
        guard cameraPermissions else {
            let permissionsAlertController = UIAlertController(title: "Permisos", message: "No tiene permisos para acceder a la cámara del dispositivo. Puede cambiar esta información en la app de ajustes de iOS", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
            permissionsAlertController.addAction(okAction)
            present(permissionsAlertController, animated: true, completion: nil)
            
            return
        }
        
        let alertControler = UIAlertController(title: "Añadir foto del videojuego", message: "", preferredStyle: .actionSheet)
        
        let cameraOption = UIAlertAction(title: "Cámara", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        
        let cameraRollOption = UIAlertAction(title: "Cámara", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        
        let cancelOption = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            alertControler.addAction(cameraOption)
        }
        alertControler.addAction(cameraRollOption)
        alertControler.addAction(cancelOption)
        
        present(alertControler, animated: true, completion: nil)
    }
    
    //Set the selected image from camera or camera roll to the game image view
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.gameImageView.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func datePickerChangedValue(picker: UIDatePicker) {
        txtBorrowedDate.text = dateFormatter.string(from: picker.date)
    }
    
    func saveButtonPressed() {
        saveGame()
        dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    func saveGame() {
        if let context = self.managedObjectContext {
            
            var editedGame : Game? = nil
            if game == nil {
                editedGame = Game(context: context)
            } else {
                editedGame = game
            }
            
            if let editedGame = editedGame {
                editedGame.dateCreated = NSDate()
                
                if let title = txtTitle.text {
                    editedGame.title = title
                }
                
                editedGame.borrowed = borrowedSwitch.isOn

                if let image = gameImageView.image {
                    editedGame.image = UIImagePNGRepresentation(image) as NSData?
                } else {
                    editedGame.image = NSData()
                }
                
                if editedGame.borrowed {
                    if let borrowedTo = txtBorrowedTo.text {
                        editedGame.borrowedTo = borrowedTo.uppercased()
                    }
                    
                    if let strDate = txtBorrowedDate.text {
                        editedGame.borrowedDate = dateFormatter.date(from: strDate) as NSDate?
                    }
                } else {
                    editedGame.borrowedTo = nil
                    editedGame.borrowedDate = nil
                }
                
                do {
                    try context.save()
                    self.delegate?.didAddGame()
                } catch {
                    print("Ha ocurrido un error al guardar los datos en Core Data")
                }
            }
        }
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            txtBorrowedTo.isEnabled = true
            txtBorrowedDate.isEnabled = true
            txtBorrowedDate.text = dateFormatter.string(from: Date())
        } else {
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
            txtBorrowedTo.text = ""
            txtBorrowedDate.text = ""
        }
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
        if let context = self.managedObjectContext {
            context.delete(game!)
            game = nil
            self.delegate?.didAddGame()
            let _ = navigationController?.popViewController(animated: true)
        }
    }
    
}
