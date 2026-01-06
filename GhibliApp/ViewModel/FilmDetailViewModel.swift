import Foundation
import Observation

@Observable
class FilmDetailViewModel {
    
    var state: LoadingState<[Person]> = .idle
    
    private let service: GhibliServiceProtocol
    
    init(service: GhibliServiceProtocol = GhibliService()) {
        self.service = service
    }
    
    func fetch(for film: Film) async {
        guard !state.isLoading else { return }
        
        state = .loading
        
        var loadedPeople: [Person] = []
    
        do {
            try await withThrowingTaskGroup(of: Person.self) { group in
                
                for personInfoURL in film.people {
                    group.addTask {
                        try await self.service.fetchPerson(from: personInfoURL)
                    }
                }
                
                // collect results as they complete
                for try await person in group {
                    loadedPeople.append(person)
                }
            }
            
            state = .loaded(loadedPeople)
            
            
        }  catch let error as APIError {
            self.state = .error(error.errorDescription ?? "unknown error")
        } catch {
            self.state = .error("unknown error")
        }
    }
}
