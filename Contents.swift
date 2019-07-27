//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

struct ViewState {
    var buildings: [Building] = []
}

class ViewController: UIViewController {
    let buildingLabel = UILabel()
    var onButtonTap: () -> Void = { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Fetch buildings", for: .normal)
        button.addTarget(
            self,
            action: #selector(fetchBuildings),
            for: .touchUpInside
        )
        
        buildingLabel.text = "Loading"
        buildingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        view.addSubview(buildingLabel)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    func render(_ state: ViewState) {
        buildingLabel.text = state.buildings.first?.name ?? "Empty"
    }
    
    @objc func fetchBuildings() {
        onButtonTap()
    }
}

struct Building: CustomStringConvertible {
    let name: String
    
    var description: String { return name }
}

protocol BuildingRepository {
    func buildings(onComplete: ([Building]) -> Void)
}

func serializeBuilding(_ building: Building) -> [String: Any] {
    return [
        "name": building.name
    ]
}

struct Server {
    let buildingRepository: BuildingRepository
    
    func fetchBuildings(buildingSerializer: (Building) -> [String: Any] = serializeBuilding,  onComplete: ([[String: Any]]) -> Void) {
        buildingRepository.buildings { buildings in
            onComplete(buildings.map(serializeBuilding))
        }
    }
    
    func filterBuildings(onComplete: ([Building]) -> Void) {
        let buildings = [
            Building(name: "Within filter")
        ]
        onComplete(buildings)
    }
}

func buildingDeserializer(_ json: [String: Any]) -> Building? {
    if let name = json["name"] as? String {
        return Building(name: name)
    }
    
    return nil
}

class Client {
    let server: Server
    var viewState: ViewState {
        didSet {
            subscriptions.forEach { $0(viewState) }
        }
    }
    var subscriptions: [(ViewState) -> Void] = []
    
    init(server: Server, viewState: ViewState = ViewState())  {
        self.server = server
        self.viewState = viewState
    }
    
    func addSubscription(_ subscription: @escaping (ViewState) -> Void) {
        subscriptions.append(subscription)
    }
    
    func showHomeScreen(buildingDeserializer: ([String: Any]) -> Building? = buildingDeserializer) {
        server.fetchBuildings { buildings in
            viewState.buildings = buildings.compactMap(buildingDeserializer)
        }
    }
    
    func filterBuildings(byName name: String) {
        server.filterBuildings { buildings in
            viewState.buildings = buildings
        }
    }
}

//: Test: When the app starts, a list of buildings are shown

struct StubBuildingRepository: BuildingRepository {
    func buildings(onComplete: ([Building]) -> Void) {
        let buildings = [
            Building(name: "Empire State Building"),
            Building(name: "Test Building")
        ]
        onComplete(buildings)
    }
}

func testDisplayingBuildingList() {
    let server = Server(buildingRepository: StubBuildingRepository())
    let client = Client(server: server)
    
    client.showHomeScreen()
    
    print("A list of buildings should be shown")
    print((client.viewState.buildings.map { $0.name }) == ["Empire State Building", "Test Building"])
}

//: Test: Filtering buildings,

func testFilteringBuildings() {
    let server = Server(buildingRepository: StubBuildingRepository())
    let client = Client(server: server)
    client.viewState = ViewState(
        buildings: [
            Building(name: "Out of filter"),
            Building(name: "Within filter")
        ]
    )
    
    client.filterBuildings(byName: "Within filter")
    
    print("A filtered list of buildings should be shown")
    print((client.viewState.buildings.map { $0.name }) == ["Within filter"])
}

//: Test: All Buildings Integration Contract

struct DatabaseBuildingRepository: BuildingRepository {
    func buildings(onComplete: ([Building]) -> Void) {
        // fetch buildings from database
        let buildings = [Building(name: "Test Building")]
        onComplete(buildings)
    }
}

func testAllBuildingsRepositoryContract() {
    let databaseBuildingRepository = DatabaseBuildingRepository()

    // async assert
    print("Fetching all buildings from the database should return all known buildings")
    databaseBuildingRepository.buildings { buildings in
        if buildings.count != 1 {
            print(false)
        } else {
            print(true)
        }
    }
}

testFilteringBuildings()
testDisplayingBuildingList()
testAllBuildingsRepositoryContract()


let server = Server(buildingRepository: StubBuildingRepository())
let client = Client(server: server)

let vc = ViewController()
vc.onButtonTap = {
    client.showHomeScreen()
}
client.addSubscription(vc.render)

PlaygroundPage.current.liveView = vc

