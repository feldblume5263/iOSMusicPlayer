//
//  MiniPlayerView.swift
//  Music-Player
//
//  Created by Junhong Park on 2022/01/15.
//

import SwiftUI
import MediaPlayer

enum RepeatMode: CaseIterable {
    case noRepeat
    case albumRepeat
    case oneSongRepeat
}

// 현재 재생하고 있는 곡 정보 모델
struct NowPlayingSong {
    var title: String
    var albumTitle: String
    var artist: String
    var artWork: UIImage
    var totalRate: Double
}

// 현재 재생되는 부분이 바뀔 때 뷰가 그려지도록
class MiniPlayerViewModel: ObservableObject {
    @Published var nowPlayingSong = NowPlayingSong(title: "", albumTitle: "", artist: "", artWork: UIImage(), totalRate: 1.0)
    @Published var playbackState: MPMusicPlaybackState? = MPMusicPlayerController.applicationMusicPlayer.playbackState
    @Published var repeatMode: RepeatMode = .noRepeat
    @Published var isShuffle: Bool = false
    
    func changeRepeatMode() -> MPMusicRepeatMode {
        repeatMode = repeatMode.next()
        switch repeatMode {
        case .noRepeat:
            return MPMusicRepeatMode.none
        case .albumRepeat:
            return MPMusicRepeatMode.all
        case .oneSongRepeat:
            return MPMusicRepeatMode.one
        }
    }
    
    func makeNowPlayingSong(title: String?, albumeTitle: String?, artist: String?, artWork: MPMediaItemArtwork?, totalRate: Double?) {
        self.nowPlayingSong.title = title ?? ""
        self.nowPlayingSong.albumTitle = albumeTitle ?? ""
        self.nowPlayingSong.artist = artist ?? ""
        self.nowPlayingSong.artWork = artWork?.image(at: CGSize(width: 100, height: 100)) ?? UIImage()
        self.nowPlayingSong.totalRate = totalRate ?? 10.0
    }
}

struct VolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        MPVolumeView(frame: .zero)
    }
    
    func updateUIView(_ view: MPVolumeView, context: Context) {
        let temp = view.subviews
        for current in temp {
            if current.isKind(of: UISlider.self) {
                let tempSlider = current as! UISlider
                tempSlider.minimumTrackTintColor = .blue
                tempSlider.maximumTrackTintColor = .systemMint
            }
        }
    }
}


struct MiniPlayerView: View {
    @ObservedObject var playerViewModel = MiniPlayerViewModel()
    var player: MPMusicPlayerController
    @Binding var isFullPlayer: Bool
    @State var playbackState: MPMusicPlaybackState? = MPMusicPlayerController.applicationMusicPlayer.playbackState
    @State var progressRate:Double = 0.0
    
    
    var body: some View {
        VStack {
            if isFullPlayer {
                Spacer()
            }
            VStack() {
                if !isFullPlayer {
                    ProgressView(value: progressRate, total: playerViewModel.nowPlayingSong.totalRate)
                }
                HStack() {
                    
                    if !isFullPlayer {
                        playPauseButton()
                        Spacer()
                        contentInfoText()
                        Spacer()
                    }
                    VStack {
                        if isFullPlayer {
                            Spacer()
                            HStack {
                                Button("Close") {
                                    DispatchQueue.global(qos: .userInteractive).async {
                                        withAnimation(Animation.easeOut(duration: 0.3)) {
                                            self.isFullPlayer.toggle()
                                        }
                                    }
                                }
                                .frame(width: 100, height: 50)
                                Spacer()
                                contentInfoText()
                                    .frame(alignment: .center)
                                Spacer()
                            }
                            Divider()
                        }
                        
                        Image(uiImage: playerViewModel.nowPlayingSong.artWork)
                            .resizable()
                            .frame(maxWidth: isFullPlayer ? .infinity : 50, maxHeight: isFullPlayer ? .infinity : 50)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.bottom)
                if isFullPlayer {
                    makefullPlayerView()
                }
            }
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
            .background(Color.white.onTapGesture {
                if !isFullPlayer {
                    DispatchQueue.global(qos: .userInteractive).async {
                        withAnimation(Animation.easeOut(duration: 0.3)) {
                            self.isFullPlayer.toggle()
                        }
                    }
                }
            })
            .cornerRadius(10)
            .shadow(radius: 3)
            .onReceive(NotificationCenter.default.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)){ _ in
                playbackState = MPMusicPlayerController.applicationMusicPlayer.playbackState
                playbackState?.printState()
            }
            .onReceive(NotificationCenter.default.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)){ _ in
                let song = player.nowPlayingItem
                playerViewModel.makeNowPlayingSong(title: song?.title,
                                                   albumeTitle: song?.albumTitle,
                                                   artist: song?.artist,
                                                   artWork: song?.artwork,
                                                   totalRate: player.nowPlayingItem?.playbackDuration)
            }
            .onAppear {
                DispatchQueue.global(qos: .background).async {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        progressRate = player.currentPlaybackTime
                    }
                    // Combine으로 해보기.
                    RunLoop.current.run()
                }
            }
        }
    }
    
    private func makefullPlayerView() -> some View {
        VStack{
            Spacer()
            HStack {
                Button {
                    player.repeatMode = playerViewModel.changeRepeatMode()
                } label: {
                    switch playerViewModel.repeatMode {
                    case .noRepeat:
                        Image(systemName: "repeat")
                            .font(.title)
                            .foregroundColor(.secondary)
                    case .albumRepeat:
                        Image(systemName: "repeat")
                            .font(.title)
                            .foregroundColor(.black)
                    case .oneSongRepeat:
                        Image(systemName: "repeat.1")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                Spacer()
                Button {
                    if player.currentPlaybackTime > 5 {
                        player.skipToBeginning()
                    } else {
                        player.skipToPreviousItem()
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundColor(.black)
                }
                Spacer()
                playPauseButton()
                Spacer()
                Button {
                    player.skipToNextItem()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(.black)
                }
                Spacer()
                Button {
                    player.shuffleMode = player.shuffleMode == .off ? MPMusicShuffleMode.songs : MPMusicShuffleMode.off
                    playerViewModel.isShuffle = player.shuffleMode == .off ? false : true
                } label: {
                        Image(systemName: "shuffle")
                            .font(.title)
                            .foregroundColor(player.shuffleMode == .off ? .secondary : .black)
                }
            }
            Spacer()
            VolumeSlider()
                .frame(height: 40)
                .padding(.horizontal)
            Spacer()
            ProgressView(value: progressRate < 0 ? progressRate * -1: progressRate, total: player.nowPlayingItem?.playbackDuration ?? 0)
            Spacer()
        }
    }
    
    private func contentInfoText() -> some View {
        VStack(alignment: .center) {
            Text(playerViewModel.nowPlayingSong.title)
            Text(playerViewModel.nowPlayingSong.artist)
                .foregroundColor(.red)
        }
    }
    
    private func playPauseButton() -> some View {
        Button {
            DispatchQueue.global(qos: .userInteractive).async {
                playbackState == .playing ? pauseSong() : playSong()
            }
        } label: {
            (playbackState == .playing ? Image(systemName: "pause.fill") : Image(systemName: "play.fill"))
                .font(.largeTitle)
                .foregroundColor(.black)
        }
    }
    
    private func playSong() {
        player.play()
    }
    
    private func pauseSong() {
        player.pause()
    }
}
