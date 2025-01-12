import Foundation
import MapKit

class AddressSearchCompleter: NSObject, ObservableObject {
    @Published var searchResults = [MKLocalSearchCompletion]()
    private var searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address // Limit to addresses for relevance
    }
    
    func startSearching(for query: String) {
        // Directly update queryFragment for dynamic updates
        if query.isEmpty {
            searchResults = []
        } else {
            searchCompleter.queryFragment = query
        }
    }
    
    func clearResults() {
        searchResults = []
    }
}

extension AddressSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { // Ensure UI updates are performed on the main thread
            self.searchResults = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error searching for addresses: \(error.localizedDescription)")
    }
}
