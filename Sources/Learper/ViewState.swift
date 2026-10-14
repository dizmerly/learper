import SwiftUI

// Select the State property wrapper explicitly. Some SDKs also export a State
// macro whose implementation is absent from Command Line Tools installations.
// The alias preserves SwiftUI's storage, bindings, and view invalidation.
typealias ViewState<Value> = SwiftUI.State<Value>
