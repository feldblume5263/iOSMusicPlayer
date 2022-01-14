//
//  AlbumDetailView.swift
//  Music-Player
//
//  Created by Junhong Park on 2022/01/13.
//

import SwiftUI
import MediaPlayer
import AVFoundation

struct AlbumDetailView: View {
    
    var album: Album
    @Binding var isViewDisplaying: Bool
    @Binding var songQueue: [MPMediaItem]?
    @ObservedObject var albumDetail = AlbumDetailViewModel()
    
    var body: some View {
        Text("\(album.albumTitle)")
        Text("\(album.albumArtist)")
        HStack {
            Button {
                songQueue = albumDetail.allSongsPlayButtonPressed()
            } label: {
                Image(systemName: "play.fill")
            }
            .padding()
            Button {
                
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .padding()
            
        }
        List {
            ForEach(0 ..< albumDetail.getSongsCount(), id: \.self) { songIndex in
                HStack {
                    Text("\(songIndex + 1)")
                        .frame(minWidth: 10, idealWidth: 15, maxWidth: 30)
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        .lineLimit(1)
                    Text(albumDetail.inAlbum?.songs[songIndex].title ?? undefinedString)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onAppear {
            initSongsInAlbum()
            isViewDisplaying = true
        }
        .onDisappear {
            isViewDisplaying = false
        }
    }
    
    func initSongsInAlbum() {
        albumDetail.setSongsInAlbumDetail(albumTitle: album.albumTitle)
    }
}

