import UIKit
import Firebase

class FirebaseIO: NSObject {

    func addnew(username:String!,faceID:String! ,completion:@escaping () -> ()){
        let data = ["username": username ]
        db.collection("userList").document(faceID).setData([
            "username": username,
            "latitude": lati,
            "longitude": long
        ])
        { (error) in
           if let error = error {
              print(error)
           }else{
            print("Document added with ID:")
            }
        }
        completion()
    }
}
