import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            SearchView(appState: appState)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            MyBooksView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("My Books")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    MainTabView()
} 