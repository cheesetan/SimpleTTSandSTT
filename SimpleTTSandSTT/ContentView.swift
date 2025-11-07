//
//  ContentView.swift
//  SimpleTTSandSTT
//
//  Created by Tristan Chay on 8/11/25.
//

import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    let synthesiser = AVSpeechSynthesizer()

    let audioEngine = AVAudioEngine()
    let speechRecogniser = SFSpeechRecognizer(locale: .current)
    @State var transcription = ""

    var body: some View {
        VStack {
            Button("Synthesise") {
                let utterance = AVSpeechUtterance(string: "Hello, World!")

                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                synthesiser.speak(utterance)
            }

            Text(transcription)
            Button("Recognise") {
                // Check for permission
                SFSpeechRecognizer.requestAuthorization { status in
                    guard status == .authorized else { return }
                }

                Task {
                    let micGranted = await AVAudioApplication.requestRecordPermission()
                    guard micGranted else { return }
                }

                guard let recogniser = speechRecogniser, recogniser.isAvailable else { return }

                // Setting AVAudioSession
                let audioSession = AVAudioSession.sharedInstance()
                try? audioSession.setCategory(.record, mode: .measurement)
                try? audioSession.setActive(true)

                // Request and "tap" handling
                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true

                let inputNode = audioEngine.inputNode
                let format = inputNode.outputFormat(forBus: 0)

                inputNode.removeTap(onBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                    request.append(buffer)
                }
                audioEngine.prepare()
                try? audioEngine.start()

                recogniser.recognitionTask(with: request) { result, _ in
                    if let result {
                        transcription = result.bestTranscription.formattedString
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
