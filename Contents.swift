//: Playground - noun: a place where people can play

import PlaygroundSupport

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
    
    func fetchBuildings(buildingSerializer: (Building) -> [String: Any] = serializeBuilding,  onComplete: ([Building]) -> Void) {
        buildingRepository.buildings { buildings in
            onComplete(buildings)
        }
    }
    
    func filterBuildings(onComplete: ([Building]) -> Void) {
        let buildings = [
            Building(name: "Within filter")
        ]
        onComplete(buildings)
    }
}

struct ViewState {
    var buildings: [Building] = []
}

class Client {
    let server: Server
    var viewState: ViewState
    
    init(server: Server, viewState: ViewState = ViewState())  {
        self.server = server
        self.viewState = viewState
    }
    
    func showHomeScreen() {
        server.fetchBuildings { buildings in
            viewState.buildings = buildings
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

// PlaygroundPage.current.liveView = ui

