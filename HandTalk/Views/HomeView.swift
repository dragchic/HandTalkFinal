import SwiftUI

struct HomeView: View {
    @State private var showStoryView = false
    @State private var showChapters = false
    @State private var jumpIndex = 0
    @State private var startChapter = false
    
    var body: some View {
        ZStack {
            Image("home_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 20) {
                    Spacer()
                    
                    if (!showChapters) {
                        Button {
                            showStoryView = true
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Start")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            showChapters = true
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Chapters")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Setting")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("About")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                    } else {
                        Button {
                            showChapters = false
                        } label: {
                            Image(systemName: "x.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            jumpIndex = 0
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Hello")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            jumpIndex = 1
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Sad")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            jumpIndex = 2
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Friend")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            jumpIndex = 3
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Eat")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            jumpIndex = 4
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("Thank You")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Button {
                            jumpIndex = 5
                        } label: {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(width: 305, height: 76)
                                Text("See You")
                                    .ShantellSans(weight: .bold, size: 40)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 36)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showStoryView) {
            InitialStoryView()
        }
        .fullScreenCover(isPresented: $startChapter) {
            InitialStoryView(currentStoryIndex: jumpIndex)
        }
        .onChange(of: jumpIndex) {
            if jumpIndex > 0 {
                startChapter = true
            }
        }
    }
}

#Preview {
    HomeView()
}
